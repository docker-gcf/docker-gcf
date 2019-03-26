base:
    '*': {{ salt['docker-gcf.find_all_states']() | yaml }}
