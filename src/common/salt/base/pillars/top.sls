base:
    '*': {{ salt['docker-gcf.find_all_pillars']() | yaml }}