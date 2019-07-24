local settings = {}

settings.word_crab_file = 'data/word_crab/words.txt'

-- 登陆认证服
settings.login_conf = {
    node_name                   = "loginnode",
    console_port                = 15010,
    login_port_http             = 15110,   --(暴露) 登陆认证端口
    login_port_tcp              = 15111,   --(暴露) 登录认证端口

    login_slave_cout            = 8,      -- 登陆认证代理个数
    api_server_ca               = "hDJ^54D@!&DHkkdh095hj"
}

-- 中心服
settings.center_conf = {
    node_name                   = "centernode",
    console_port                = 15020,
}

settings.nodes = {
        ['node1'] = {
            -- 网络配置
            node_name           = "node1",  -- 每个lobby名字必须唯一
            console_port        = 15030, -- 执行关服操作 stop.sh 中 EXIT_PORT 也要保持一致
            gate_switch         = {"ws", "tcp", }, -- 定义可以开启的gate 端口
            host                = "0.0.0.0", -- 需要手动修改
            gate_port_tcp       = 15120, 	--(暴露 网关端口 TCP)
            gate_port_ws        = 15121, --(暴露 网关端口 WS)
            max_client          = 4000,
            nodelay             = true,
        },
    }

settings.battles = {
    ['battle1'] = {
        battle_name             = "battle1",  -- 每个battle名字必须唯一
        console_port            = 15040, -- 执行关服操作 stop.sh 中 EXIT_PORT 也要保持一致
        host                    = "0.0.0.0", -- 需要手动修改
        port                    = 15220, -- udp 开启对gate 端口
        battled_name            = "battle1d",
    },
    ['battle2'] = {
        battle_name             = "battle2",  -- 每个battle名字必须唯一
        console_port            = 15041, -- 执行关服操作 stop.sh 中 EXIT_PORT 也要保持一致
        host                    = "0.0.0.0", -- 需要手动修改
        port                    = 15221, -- udp 开启对gate 端口
        battled_name            = "battle2d",
    },
}

--db 配置
settings.db_cnf = {
    loginnode = {
        redis_maxinst = 4,
        redis_cnf = {
            host = "127.0.0.1",
            port = 16379,
            db = 0,
        },

        dbproxy = "mongodb",
        mongodb_maxinst = 8,
        mongodb_cnf = {
            host = "127.0.0.1",
            port = "27017",
        },
    },

    centernode = {
        redis_maxinst = 4,
        redis_cnf = {
            host = "127.0.0.1",
            port = 16379,
            db = 0,
        }
    },

    node1 = {
        redis_maxinst = 4,
        redis_cnf = {
            host = "127.0.0.1",
            port = 16379,
            db = 0,
        },

        dbproxy = "mongodb",

        mongodb_maxinst = 8,
        mongodb_cnf = {
            host = "127.0.0.1",
            port = "27017",
        },
    },

    battle1 = {
        redis_maxinst = 2,
        redis_cnf = {
            host = "127.0.0.1",
            port = 16379,
            db = 0,
        },

        dbproxy = "mongodb",

        mongodb_maxinst = 4,
        mongodb_cnf = {
            host = "127.0.0.1",
            port = "27017",
        },        
    },

    battle2 = {
        redis_maxinst = 2,
        redis_cnf = {
            host = "127.0.0.1",
            port = 16379,
            db = 0,
        },

        dbproxy = "mongodb",

        mongodb_maxinst = 4,
        mongodb_cnf = {
            host = "127.0.0.1",
            port = "27017",
        },        
    }
}

return settings
