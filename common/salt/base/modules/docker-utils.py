import json
import os


def get_model_from_env(env_dict: dict = os.environ, env_prefix: str = "GCF", env_separator: str = "."):
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
                sub_model[names[-1]] = __salt__['slsutil.merge'](existing, env_value_json)
            else:
                sub_model[names[-1]] = env_value_json

    return model
