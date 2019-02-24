import os
import tempfile
import unittest

import jsonschema

import common.gcf


def get_generator(config_dir=''):
    options = common.gcf.Options()
    options.jinja_ext_only = True
    options.sync_command = "rsync -rlptDH --delete %s %s"
    options.env_prefix = "GCF."
    options.base_config_path = config_dir

    generator = common.gcf.Generator()

    return generator, options


class GenerateConfigFilesTests(unittest.TestCase):
    def test_build_model_empty(self):
        model_dict = {}

        target = common.gcf.Target()
        target.effective_generate_option.template_model = {}

        model = common.gcf.Helpers.build_model(model_dict, target)

        self.assertDictEqual({}, model)

    def test_build_model_ignored_keys(self):
        model_dict = {"test.foo": 42}

        target = common.gcf.Target()
        target.effective_generate_option.template_model = {}
        target.effective_generate_option.env_prefix = "GCF."

        model = common.gcf.Helpers.build_model(model_dict, target)

        self.assertDictEqual({}, model)

    def test_build_model_base_model(self):
        model_dict = {}

        config_json = {
            "targets":
                [
                    {
                        "input": "apache2.conf",
                        "output": "/etc/apache2/apache2.conf"
                    }
                ],
            "template_model": {
                "test": 42
            }
        }
        jsonschema.validate(config_json, common.gcf.CONFIG_SCHEMA)
        options = common.gcf.Options()
        common.gcf.Helpers.populate_options(config_json, options)
        common.gcf.Helpers.build_options({}, options)
        target = options.targets[0]

        model = common.gcf.Helpers.build_model(model_dict, target)

        self.assertDictEqual({
            "test": 42
        }, model)

    def test_build_model_1(self):
        model_dict = {"GCF.test": "42"}

        config_json = {
            "targets":
                [
                    {
                        "input": "apache2.conf",
                        "output": "/etc/apache2/apache2.conf"
                    }
                ]
        }
        jsonschema.validate(config_json, common.gcf.CONFIG_SCHEMA)
        options = common.gcf.Options()
        common.gcf.Helpers.populate_options(config_json, options)
        common.gcf.Helpers.build_options({}, options)
        target = options.targets[0]

        model = common.gcf.Helpers.build_model(model_dict, target)

        self.assertDictEqual({
            "test": 42
        }, model)

    def test_build_model_2(self):
        model_dict = {
            "GCF.test": "42",
            "GCF.foo.bar.value": "\"test\"",
            "GCF.foo": "{\"bar\": {\"value2\": 42}}"
        }

        config_json = {
            "targets":
                [
                    {
                        "input": "apache2.conf",
                        "output": "/etc/apache2/apache2.conf"
                    }
                ]
        }
        jsonschema.validate(config_json, common.gcf.CONFIG_SCHEMA)
        options = common.gcf.Options()
        common.gcf.Helpers.populate_options(config_json, options)
        common.gcf.Helpers.build_options({}, options)
        target = options.targets[0]

        model = common.gcf.Helpers.build_model(model_dict, target)

        self.assertDictEqual({
            "test": 42,
            "foo": {
                "bar": {
                    "value": "test",
                    "value2": 42
                }
            }
        }, model)

    def test_build_model_3(self):
        model_dict = {
            "GCF.var5": "\"env\"",
            "GCF.var6": "\"env\""
        }

        config_json = {
            "targets":
                [
                    {
                        "input": "apache2.conf",
                        "output": "/etc/apache2/apache2.conf",
                        "template_model": {
                            "var3": "target",
                            "var6": "target",
                            "var7": "target",
                            "var8": "target"
                        }
                    }
                ],
            "template_model": {
                "var2": "base",
                "var6": "base",
                "var7": "base",
                "var8": "base",
                "var9": "base"
            }
        }
        jsonschema.validate(config_json, common.gcf.CONFIG_SCHEMA)
        options = common.gcf.Options()
        options.default_generate_option.template_model = {
            "var1": "default",
            "var6": "default",
            "var7": "default",
            "var8": "default",
            "var9": "default"
        }
        options.cli_generate_option.template_model = {
            "var4": "cli",
            "var6": "cli",
            "var7": "cli"
        }
        common.gcf.Helpers.populate_options(config_json, options)
        common.gcf.Helpers.build_options({}, options)
        target = options.targets[0]

        model = common.gcf.Helpers.build_model(model_dict, target)

        self.assertDictEqual({
            "var1": "default",
            "var2": "base",
            "var3": "target",
            "var4": "cli",
            "var5": "env",
            "var6": "env",
            "var7": "cli",
            "var8": "target",
            "var9": "base"
        }, model)

    def test_build_model_overwrite(self):
        model_dict = {
            "GCF.test": "42",
            "GCF.foo.bar.value": "\"test\"",
            "GCF.foo": "{\"bar\": {\"value2\": 42}}",
            "GCF.foo.bar.value2": "24"
        }

        config_json = {
            "targets":
                [
                    {
                        "input": "apache2.conf",
                        "output": "/etc/apache2/apache2.conf"
                    }
                ]
        }
        jsonschema.validate(config_json, common.gcf.CONFIG_SCHEMA)
        options = common.gcf.Options()
        common.gcf.Helpers.populate_options(config_json, options)
        common.gcf.Helpers.build_options({}, options)
        target = options.targets[0]

        model = common.gcf.Helpers.build_model(model_dict, target)

        self.assertDictEqual({
            "test": 42,
            "foo": {
                "bar": {
                    "value": "test",
                    "value2": 24
                }
            }
        }, model)

    def test_build_model_ldap(self):
        model_dict ={
                "GCF.ldap.local": "{ \"suffix\": \"dc=ad,dc=sso,dc=example,dc=com\" }",
                "GCF.ldap.local.ldapAdmin": "{ \"cn\": \"admin\", \"password\": \"admin\" }",
                "GCF.ldap.local.configAdmin": "{ \"cn\": \"admin\", \"password\": \"admin\" }",
                "GCF.ldap.remote.suffix": "\"dc=ad,dc=sso,dc=example,dc=com\""
            }

        config_json = {
            "targets":
                [
                    {
                        "input": "apache2.conf",
                        "output": "/etc/apache2/apache2.conf"
                    }
                ]
        }
        jsonschema.validate(config_json, common.gcf.CONFIG_SCHEMA)
        options = common.gcf.Options()
        common.gcf.Helpers.populate_options(config_json, options)
        common.gcf.Helpers.build_options({}, options)
        target = options.targets[0]

        model = common.gcf.Helpers.build_model(model_dict, target)

        self.assertDictEqual({
            "ldap": {
                "local": {
                    "suffix": "dc=ad,dc=sso,dc=example,dc=com",
                    "ldapAdmin": {
                        "cn": "admin",
                        "password": "admin"
                    },
                    "configAdmin": {
                        "cn": "admin",
                        "password": "admin"
                    }
                },
                "remote": {
                    "suffix": "dc=ad,dc=sso,dc=example,dc=com"
                }
            }
        }, model)

    def test_simple_file(self):
        with tempfile.TemporaryDirectory() as dirpath:
            config_json = {
                "targets":
                    [
                        {
                            "input": "apache2.conf",
                            "output": os.path.join(dirpath, "apache2.conf")
                        }
                    ]
            }
            jsonschema.validate(config_json, common.gcf.CONFIG_SCHEMA)
            options = common.gcf.Options()
            options.base_config_path = "./test_simple_file/config"
            options.dump_model_file = "%s/gcf-model.json" % dirpath
            common.gcf.Helpers.populate_options(config_json, options)
            common.gcf.Helpers.build_options({}, options)

            generator = common.gcf.Generator()
            generator.generate_targets(options)

            with open(os.path.join(dirpath, "apache2.conf")) as f:
                content = f.read()

            self.assertEqual("ServerName hello-there\n", content)

    def test_simple_file_template_jinja_only(self):
        with tempfile.TemporaryDirectory() as dirpath:
            config_json = {
                "targets":
                    [
                        {
                            "input": "apache2.conf",
                            "output": os.path.join(dirpath, "apache2.conf"),
                            "jinja_ext_only": True
                        }
                    ]
            }
            jsonschema.validate(config_json, common.gcf.CONFIG_SCHEMA)
            options = common.gcf.Options()
            options.base_config_path = "./test_simple_file_template/config"
            options.dump_model_file = "%s/gcf-model.json" % dirpath
            common.gcf.Helpers.populate_options(config_json, options)
            common.gcf.Helpers.build_options({"GCF.host": "\"my-hostname\""}, options)

            generator = common.gcf.Generator()
            generator.generate_targets(options)

            with open(os.path.join(dirpath, "apache2.conf")) as f:
                content = f.read()

            self.assertEqual("ServerName {{ model.host }}\n", content)

    def test_simple_file_template_all_files(self):
        with tempfile.TemporaryDirectory() as dirpath:
            config_json = {
                "targets":
                    [
                        {
                            "input": "apache2.conf",
                            "output": os.path.join(dirpath, "apache2.conf"),
                            "jinja_ext_only": False
                        }
                    ]
            }
            jsonschema.validate(config_json, common.gcf.CONFIG_SCHEMA)
            options = common.gcf.Options()
            options.base_config_path = "./test_simple_file_template/config"
            options.dump_model_file = "%s/gcf-model.json" % dirpath
            common.gcf.Helpers.populate_options(config_json, options)
            common.gcf.Helpers.build_options({"GCF.host": "\"my-hostname\""}, options)

            generator = common.gcf.Generator()
            generator.generate_targets(options)

            with open(os.path.join(dirpath, "apache2.conf")) as f:
                content = f.read()

            self.assertEqual("ServerName my-hostname\n", content)

    def test_simple_file_jinja_template_jinja_only(self):
        with tempfile.TemporaryDirectory() as dirpath:
            config_json = {
                "targets":
                    [
                        {
                            "input": "apache2.conf.jinja",
                            "output": os.path.join(dirpath, "apache2.conf.jinja"),
                            "jinja_ext_only": True
                        }
                    ]
            }
            jsonschema.validate(config_json, common.gcf.CONFIG_SCHEMA)
            options = common.gcf.Options()
            options.base_config_path = "./test_simple_file_template/config"
            options.dump_model_file = "%s/gcf-model.json" % dirpath
            common.gcf.Helpers.populate_options(config_json, options)
            common.gcf.Helpers.build_options({"GCF.host": "\"my-hostname\""}, options)

            generator = common.gcf.Generator()
            generator.generate_targets(options)

            with open(os.path.join(dirpath, "apache2.conf")) as f:
                content = f.read()

            self.assertEqual("ServerName my-hostname\n", content)

    def test_simple_file_jinja_template_all_files(self):
        with tempfile.TemporaryDirectory() as dirpath:
            config_json = {
                "targets":
                    [
                        {
                            "input": "apache2.conf.jinja",
                            "output": os.path.join(dirpath, "apache2.conf.jinja"),
                            "jinja_ext_only": False
                        }
                    ]
            }
            jsonschema.validate(config_json, common.gcf.CONFIG_SCHEMA)
            options = common.gcf.Options()
            options.base_config_path = "./test_simple_file_template/config"
            options.dump_model_file = "%s/gcf-model.json" % dirpath
            common.gcf.Helpers.populate_options(config_json, options)
            common.gcf.Helpers.build_options({"GCF.host": "\"my-hostname\""}, options)

            generator = common.gcf.Generator()
            generator.generate_targets(options)

            with open(os.path.join(dirpath, "apache2.conf.jinja")) as f:
                content = f.read()

            self.assertEqual("ServerName my-hostname\n", content)
