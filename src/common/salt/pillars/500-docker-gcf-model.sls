model:
    {{ __salt__['docker-gcf.get_model_from_env']() | yaml }}
