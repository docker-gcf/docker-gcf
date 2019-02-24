base:
    '*': {{ salt['docker-utils.find_all_states']() }}
