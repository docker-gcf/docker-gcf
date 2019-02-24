#! /usr/bin/python3

import json
import jsonschema
import os
import shlex
import subprocess
import sys
import argparse
import jinja2
import typing

CONFIG_SCHEMA = {
    "$schema": "http://json-schema.org/draft-07/schema#",
    "type": "object",
    "properties": {
        "targets": {
            "type": "array",
            "items": {
                "type": "object",
                "properties": {
                    "name": {"type": "string"},
                    "input": {"type": "string"},
                    "output": {"type": "string"},
                    "template_model": {"type": "object"},
                    "jinja_ext_only": {"type": "boolean"},
                    "sync_command": {"type": "string"},
                    "env_prefix": {"type": "string"},
                    "env_separator": {"type": "string"}
                },
                "required": ["input", "output"]
            }
        },
        "template_model": {"type": "object"},
        "jinja_ext_only": {"type": "boolean"},
        "sync_command": {"type": "string"},
        "env_prefix": {"type": "string"},
        "env_separator": {"type": "string"}
    },
    "required": ["targets"]
}


def utils_cmd(cmd):
    res = subprocess.run(cmd, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    return res


class GenerateOptions:
    def __init__(self):
        self.template_model = None
        self.jinja_ext_only = None
        self.sync_command = None
        self.env_prefix = None
        self.env_separator = None


class Target:
    def __init__(self):
        self.name = None
        self.input = None
        self.output = None
        self.target_generate_option = GenerateOptions()
        self.effective_generate_option = GenerateOptions()


class Options:
    def __init__(self):
        self.default_generate_option = GenerateOptions()
        self.default_generate_option.template_model = {}
        self.default_generate_option.jinja_ext_only = False
        self.default_generate_option.sync_command = "rsync -rlptDH --delete %s %s"
        self.default_generate_option.env_prefix = "GCF"
        self.default_generate_option.env_separator = "."

        self.config_generate_option = GenerateOptions()
        self.cli_generate_option = GenerateOptions()

        self.full_model = {}
        self.base_config_path = "/etc/gcf"
        self.dump_model_file = "/tmp/gcf-model.json"
        self.targets = []


class Generator:
    def __init__(self):
        self.jinja_env = jinja2.Environment(extensions=[
            'jinja2.ext.do',
            'jinja2.ext.loopcontrols'
        ],
            loader=jinja2.FileSystemLoader('.'),
            keep_trailing_newline=True)
        self.utils = {
            "cmd": utils_cmd
        }

    def sync_files(self, input_path: str, output_path: str, target: Target):
        escaped_input_path = shlex.quote(input_path)
        escaped_output_path = shlex.quote(output_path)
        cmd = target.effective_generate_option.sync_command % (escaped_input_path, escaped_output_path)
        print("==== Executing %s" % cmd)
        os.system(cmd)

    def generate_file(self, file_path: str, target: Target, options: Options):
        print("==== Processing %s" % file_path)
        if not target.effective_generate_option.jinja_ext_only or (target.effective_generate_option.jinja_ext_only and file_path.endswith(".jinja")):
            print("Rendering as jinja template")
            file_data = Helpers.read_file(file_path)
            file_template = self.jinja_env.from_string(file_data)
            context = {
                "options": options,
                "target": target,
                "file_path": file_path
            }
            output_data = file_template.render(model=target.effective_generate_option.template_model, context=context, utils=self.utils)
            Helpers.write_file(file_path, output_data)

            if target.effective_generate_option.jinja_ext_only:
                output_path = file_path[0:len(file_path) - 6]
                print("Renaming to %s" % output_path)
                os.rename(file_path, output_path)
        else:
            print("Nothing to be done")

    def generate_files(self, input_path: str, output_path: str, target: Target, options: Options):
        self.sync_files(input_path, output_path, target)
        if os.path.isfile(output_path):
            self.generate_file(output_path, target, options)
        else:
            for root, dirs, files in os.walk(output_path):
                for file_name in files:
                    file_path = os.path.join(root, file_name)
                    self.generate_file(file_path, target, options)

    def generate_targets(self, options: Options):
        for target in options.targets:
            input_path = os.path.join(options.base_config_path, target.input)
            output_path = target.output
            self.generate_files(input_path, output_path, target, options)


class Helpers:
    @staticmethod
    def str2bool(v):
        if v.lower() in ('yes', 'true', 't', 'y', '1'):
            return True
        elif v.lower() in ('no', 'false', 'f', 'n', '0'):
            return False
        else:
            raise argparse.ArgumentTypeError('Boolean value expected.')

    @staticmethod
    def merge(source, destination):
        for key, value in source.items():
            if isinstance(value, dict):
                # get node or create one
                node = destination.setdefault(key, {})
                Helpers.merge(value, node)
            else:
                destination[key] = value

        return destination

    @staticmethod
    def extract_from_env(env_dict: dict, env_prefix: str, env_separator: str):
        model = {}
        for env_name in env_dict:
            full_prefix = "%s%s" % (env_prefix, env_separator)
            if env_name.startswith(full_prefix):
                env_value_str = env_dict[env_name]
                env_value_json = json.loads(env_value_str)
                env_short_name = env_name[len(full_prefix):]

                names = env_short_name.split(env_separator)
                sub_model = model
                for i in range(len(names) - 1):
                    name = names[i]
                    if name not in sub_model:
                        sub_model[name] = {}
                    sub_model = sub_model[name]

                if isinstance(env_value_json, dict):
                    existing = sub_model[names[-1]] if names[-1] in sub_model else {}
                    sub_model[names[-1]] = Helpers.merge(existing, env_value_json)
                else:
                    sub_model[names[-1]] = env_value_json

        return model

    @staticmethod
    def build_model(model_dict: dict, target: Target):
        model = target.effective_generate_option.template_model
        for env_name in model_dict:
            full_prefix = "%s%s" % (target.effective_generate_option.env_prefix, target.effective_generate_option.env_separator)
            if env_name.startswith(full_prefix):
                env_value_str = model_dict[env_name]
                env_value_json = json.loads(env_value_str)
                env_short_name = env_name[len(full_prefix):]

                names = env_short_name.split(target.effective_generate_option.env_separator)
                sub_model = model
                for i in range(len(names) - 1):
                    name = names[i]
                    if name not in sub_model:
                        sub_model[name] = {}
                    sub_model = sub_model[name]

                if isinstance(env_value_json, dict):
                    existing = sub_model[names[-1]] if names[-1] in sub_model else {}
                    sub_model[names[-1]] = Helpers.merge(existing, env_value_json)
                else:
                    sub_model[names[-1]] = env_value_json

        return model

    @staticmethod
    def populate_generate_options(options_json: dict, options: GenerateOptions):
        if "template_model" in options_json:
            options.template_model = options_json["template_model"]
        if "jinja_ext_only" in options_json:
            options.jinja_ext_only = options_json["jinja_ext_only"]
        if "sync_command" in options_json:
            options.sync_command = options_json["sync_command"]
        if "env_prefix" in options_json:
            options.env_prefix = options_json["env_prefix"]
        if "env_separator" in options_json:
            options.env_separator = options_json["env_separator"]

    @staticmethod
    def populate_target(target_json: dict, target: Target):
        target.input = target_json["input"]
        target.output = target_json["output"]
        target.name = target_json["name"] if "name" in target_json else target_json["input"]
        Helpers.populate_generate_options(target_json, target.target_generate_option)

    @staticmethod
    def populate_options(config_json: dict, options: Options):
        Helpers.populate_generate_options(config_json, options.config_generate_option)
        for target_json in config_json["targets"]:
            target = Target()
            Helpers.populate_target(target_json, target)
            options.targets.append(target)

        options.full_model = {}
        for target in options.targets:
            options.full_model[target.name] = target.effective_generate_option.template_model

    @staticmethod
    def coalesce_property(objects: list, property_lambda: typing.Callable[[object], object], default_value=None):
        for obj in objects:
            value = property_lambda(obj)
            if value is not None:
                return value
        return default_value

    @staticmethod
    def build_options(model_dict: dict, options: Options):
        for target in options.targets:
            env_generate_option = GenerateOptions()
            env_generate_option.template_model = Helpers.extract_from_env(model_dict,
                                                                          target.effective_generate_option.env_prefix,
                                                                          target.effective_generate_option.env_separator)
            generate_options = [env_generate_option, options.cli_generate_option, target.target_generate_option,
                                options.config_generate_option, options.default_generate_option]
            model = {}
            for i in reversed(range(len(generate_options))):
                if generate_options[i].template_model is not None:
                    Helpers.merge(generate_options[i].template_model, model)
            target.effective_generate_option.template_model = model
            target.effective_generate_option.jinja_ext_only = Helpers.coalesce_property(generate_options, lambda x: x.jinja_ext_only)
            target.effective_generate_option.sync_command = Helpers.coalesce_property(generate_options, lambda x: x.sync_command)
            target.effective_generate_option.env_prefix = Helpers.coalesce_property(generate_options, lambda x: x.env_prefix)
            target.effective_generate_option.env_separator = Helpers.coalesce_property(generate_options, lambda x: x.env_separator)

    @staticmethod
    def read_file(file_path: str):
        with open(file_path, "r") as file_stream:
            file_content = file_stream.read()
        return file_content

    @staticmethod
    def write_file(file_path: str, file_content):
        with open(file_path, "w") as file_stream:
            file_stream.write(file_content)


def main():
    options = Options()

    parser = argparse.ArgumentParser(description='Generate files from plain text files and Jinja2 templates')

    parser.add_argument('--jinja-ext-only', type=Helpers.str2bool, default=None,
                        help='Process only files with .jinja extension as Jinja2 templates. '
                             'jinja extension will be removed for destination files.')
    parser.add_argument('--sync-cmd', default=None,
                        help='Command to sync files from input to output')
    parser.add_argument('--env-prefix', default=None,
                        help='Prefix for env variables')
    parser.add_argument('--env-separator', default=None,
                        help='Separator for env variables')

    parser.add_argument('--base-config-path', default=options.base_config_path,
                        help='Path where configuration templates are stored. Default=%s' % options.base_config_path)
    parser.add_argument('--dump-model-path', default=options.dump_model_file,
                        help='Dump JSON model to the specified file. Default=%s' % options.dump_model_file)

    args = parser.parse_args()

    options.cli_generate_option.jinja_ext_only = args.jinja_ext_only
    options.cli_generate_option.sync_command = args.sync_cmd
    options.cli_generate_option.env_prefix = args.env_prefix
    options.cli_generate_option.env_separator = args.env_separator

    options.base_config_path = args.base_config_path
    options.dump_model_file = args.dump_model_file

    with open(os.path.join(options.base_config_path, "gcf.json"), "r") as targets_file:
        config_json = json.load(targets_file)
    jsonschema.validate(config_json, CONFIG_SCHEMA)

    Helpers.populate_options(config_json, options)
    Helpers.build_options(os.environ, options)

    with open(options.dump_model_file, "w") as f:
        json.dump(options.full_model, f)

    generator = Generator()
    generator.generate_targets(options)

    return 0


if __name__ == "__main__":
    sys.exit(main())
