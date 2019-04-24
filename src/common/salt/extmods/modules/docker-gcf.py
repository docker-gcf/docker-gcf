import json
import os


def get_model_from_env(env_dict=os.environ, env_prefix="GCF", env_separator="__"):
    model = {}
    for env_name in env_dict:
        full_prefix = "%s%s" % (env_prefix, env_separator)
        if env_name.startswith(full_prefix) or env_name == env_prefix:
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
                sub_model[names[-1]] = __salt__['slsutil.merge'](existing, env_value_json)
            else:
                sub_model[names[-1]] = env_value_json

    return model


def find_all_sls(dir_path):
    sls = []
    entries = os.listdir(dir_path)
    list.sort(entries)
    for f in entries:
        if f.endswith(".sls"):
            if f != "top.sls":
                sls.append(f[0:-4])
        else:
            sls.append(f)
    return sls


def find_all_pillars():
    return find_all_sls("/etc/salt/base/pillars/")


def find_all_states():
    return find_all_sls("/etc/salt/base/states/")
