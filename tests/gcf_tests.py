import os
import tempfile
import unittest
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

        generator, options = get_generator()
        model = generator.build_model(model_dict, options)

        self.assertTrue(len(model) == 0)

    def test_build_model_base_model(self):
        model_dict = {}

        generator, options = get_generator()
        options.template_model = {"test": 42}
        model = generator.build_model(model_dict, options)

        self.assertTrue(len(model) == 1)
        self.assertTrue("test" in model)
        self.assertTrue(model["test"] == 42)

    def test_build_model_ignored_keys(self):
        model_dict = {"test.foo": "42"}

        generator, options = get_generator()
        model = generator.build_model(model_dict, options)

        self.assertTrue(len(model) == 0)

    def test_build_model_1(self):
        model_dict = {"GCF.test": "42"}

        generator, options = get_generator()
        model = generator.build_model(model_dict, options)

        self.assertTrue(len(model) == 1)
        self.assertTrue("test" in model)
        self.assertTrue(model["test"] == 42)

    def test_build_model_2(self):
        model_dict = {
            "GCF.test": "42",
            "GCF.foo.bar.value": "\"test\"",
            "GCF.foo": "{\"bar\": {\"value2\": 42}}"
        }

        generator, options = get_generator()
        model = generator.build_model(model_dict, options)

        self.assertDictEqual({
            "test": 42,
            "foo": {
                "bar": {
                    "value": "test",
                    "value2": 42
                }
            }
        }, model)

    def test_build_model_overwrite(self):
        model_dict = {
            "GCF.test": "42",
            "GCF.foo.bar.value": "\"test\"",
            "GCF.foo": "{\"bar\": {\"value2\": 42}}",
            "GCF.foo.bar.value2": "24"
        }

        generator, options = get_generator()
        model = generator.build_model(model_dict, options)

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

        generator, options = get_generator()
        model = generator.build_model(model_dict, options)

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
            generator, options = get_generator("./test_simple_file/config")
            options.template_model = generator.build_model({}, options)
            options.targets = [{"input": "apache2.conf", "output": os.path.join(dirpath, "apache2.conf")}]

            generator.generate_targets(options)

            with open(os.path.join(dirpath, "apache2.conf")) as f:
                content = f.read()

            self.assertEqual("ServerName hello-there\n", content)

    def test_simple_file_template_jinja_only(self):
        with tempfile.TemporaryDirectory() as dirpath:
            generator, options = get_generator("./test_simple_file_template/config")
            options.template_model = generator.build_model({"GCF.host": "\"my-hostname\""}, options)
            options.targets = [{"input": "apache2.conf", "output": os.path.join(dirpath, "apache2.conf")}]

            generator.generate_targets(options)

            with open(os.path.join(dirpath, "apache2.conf")) as f:
                content = f.read()

            self.assertEqual("ServerName {{ model.host }}\n", content)

    def test_simple_file_template_all_files(self):
        with tempfile.TemporaryDirectory() as dirpath:
            generator, options = get_generator("./test_simple_file_template/config")
            options.jinja_ext_only = False
            options.template_model = generator.build_model({"GCF.host": "\"my-hostname\""}, options)
            options.targets = [{"input": "apache2.conf", "output": os.path.join(dirpath, "apache2.conf")}]

            generator.generate_targets(options)

            with open(os.path.join(dirpath, "apache2.conf")) as f:
                content = f.read()

            self.assertEqual("ServerName my-hostname\n", content)

    def test_simple_file_jinja_template_jinja_only(self):
        with tempfile.TemporaryDirectory() as dirpath:
            generator, options = get_generator("./test_simple_file_template/config")
            options.template_model = generator.build_model({"GCF.host": "\"my-hostname\""}, options)
            options.targets = [{"input": "apache2.conf.jinja", "output": os.path.join(dirpath, "apache2.conf.jinja")}]

            generator.generate_targets(options)

            with open(os.path.join(dirpath, "apache2.conf")) as f:
                content = f.read()

            self.assertEqual("ServerName my-hostname\n", content)

    def test_simple_file_jinja_template_all_files(self):
        with tempfile.TemporaryDirectory() as dirpath:
            generator, options = get_generator("./test_simple_file_template/config")
            options.jinja_ext_only = False
            options.template_model = generator.build_model({"GCF.host": "\"my-hostname\""}, options)
            options.targets = [{"input": "apache2.conf.jinja", "output": os.path.join(dirpath, "apache2.conf.jinja")}]

            generator.generate_targets(options)

            with open(os.path.join(dirpath, "apache2.conf.jinja")) as f:
                content = f.read()

            self.assertEqual("ServerName my-hostname\n", content)
