fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'OpenAI'
description 'Ultimo Respiro style prototype: body remains as heat source, soul moves briefly'
version '0.1.0'

shared_scripts {
    'shared/config.lua'
}

client_scripts {
    'client/main.lua'
}

server_scripts {
    'server/main.lua'
}

dependencies {
    'qb-core'
}
