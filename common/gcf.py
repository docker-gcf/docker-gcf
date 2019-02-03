#! /usr/bin/python3

import json
import os
import shlex
import subprocess
import sys
import argparse
import jinja2


def utils_cmd(cmd):
    res = subprocess.run(cmd, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    return res


class Options:
    def __init__(self):
        self.template_model = {}
        self.jinja_ext_only = True
        self.sync_command = "rsync -rlptDH --delete %s %s"
        self.env_prefix = "GCF."
        self.base_config_path = "./config/"
        self.dump_model_file = None
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

    def sync_files(self, input_path: str, output_path: str, options: Options):
        escaped_input_path = shlex.quote(input_path)
        escaped_output_path = shlex.quote(output_path)
        cmd = options.sync_command % (escaped_input_path, escaped_output_path)
        print("==== Executing %s" % cmd)
        os.system(cmd)

    def read_file(self, file_path: str):
        with open(file_path, "r") as file_stream:
            file_content = file_stream.read()
        return file_content

    def write_file(self, file_path: str, file_content):
        with open(file_path, "w") as file_stream:
            file_stream.write(file_content)

    def generate_file(self, file_path: str, options: Options):
        print("==== Processing %s" % file_path)
        if not options.jinja_ext_only or (options.jinja_ext_only and file_path.endswith(".jinja")):
            print("Rendering as jinja template")
            file_data = self.read_file(file_path)
            file_template = self.jinja_env.from_string(file_data)
            context = {
                "options": options,
                "file_path": file_path
            }
            output_data = file_template.render(model=options.template_model, context=context, utils=self.utils)
            self.write_file(file_path, output_data)

            if options.jinja_ext_only:
                output_path = file_path[0:len(file_path) - 6]
                print("Renaming to %s" % output_path)
                os.rename(file_path, output_path)
        else:
            print("Nothing to be done")

    def generate_files(self, input_path: str, output_path: str, options: Options):
        self.sync_files(input_path, output_path, options)
        if os.path.isfile(output_path):
            self.generate_file(output_path, options)
        else:
            for root, dirs, files in os.walk(output_path):
                for file_name in files:
                    file_path = os.path.join(root, file_name)
                    self.generate_file(file_path, options)

    def merge(self, source, destination):
        for key, value in source.items():
            if isinstance(value, dict):
                # get node or create one
                node = destination.setdefault(key, {})
                self.merge(value, node)
            else:
                destination[key] = value

        return destination

    def build_model(self, model_dict: dict, options: Options):
        model = options.template_model
        for env_name in model_dict:
            if env_name.startswith(options.env_prefix):
                env_value_str = model_dict[env_name]
                env_value_json = json.loads(env_value_str)
                env_short_name = env_name[len(options.env_prefix):].lower()

                names = env_short_name.split('.')
                sub_model = model
                for i in range(len(names) - 1):
                    name = names[i]
                    if name not in sub_model:
                        sub_model[name] = {}
                    sub_model = sub_model[name]

                if isinstance(env_value_json, dict):
                    existing = sub_model[names[-1]] if names[-1] in sub_model else {}
                    sub_model[names[-1]] = self.merge(existing, env_value_json)
                else:
                    sub_model[names[-1]] = env_value_json

        return model

    def generate_targets(self, options: Options):
        for targets in options.targets:
            input_path = os.path.join(options.base_config_path, targets["input"])
            output_path = targets["output"]
            self.generate_files(input_path, output_path, options)


def str2bool(v):
    if v.lower() in ('yes', 'true', 't', 'y', '1'):
        return True
    elif v.lower() in ('no', 'false', 'f', 'n', '0'):
        return False
    else:
        raise argparse.ArgumentTypeError('Boolean value expected.')


def main():
    options = Options()

    parser = argparse.ArgumentParser(description='Generate files from plain text files and Jinja2 templates',
                                     formatter_class=argparse.ArgumentDefaultsHelpFormatter)

    parser.add_argument('--jinja-ext-only', type=str2bool, default=options.jinja_ext_only,
                        help='Process only files with .jinja extension as Jinja2 templates. '
                             'jinja extension will be removed for destination files.')
    parser.add_argument('--sync-cmd', default=options.sync_command, help='Command to sync files from input to output')
    parser.add_argument('--env-prefix', default=options.env_prefix, help='Prefix for env variables')
    parser.add_argument('--base-config-path', default=options.base_config_path, help='Path where configuration templates are stored')
    parser.add_argument('--dump-model-file', default=options.dump_model_file, help='Dump JSON model to the specified file')

    args = parser.parse_args()

    generator = Generator()

    options.jinja_ext_only = args.jinja_ext_only
    options.sync_command = args.sync_cmd
    options.env_prefix = args.env_prefix
    options.base_config_path = args.base_config_path
    options.dump_model_file = args.dump_model_file
    with open(os.path.join(options.base_config_path, "gcf.json"), "r") as targets_file:
        options.targets = json.load(targets_file)["targets"]
    options.template_model = generator.build_model(os.environ, options)

    if options.dump_model_file is not None:
        with open(options.dump_model_file, "w") as f:
            json.dump(options.template_model, f)

    generator.generate_targets(options)

    return 0


if __name__ == "__main__":
    sys.exit(main())
