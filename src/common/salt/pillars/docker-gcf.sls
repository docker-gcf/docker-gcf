model:
    {{ salt['docker-gcf.get_model_from_env']() | yaml }}
