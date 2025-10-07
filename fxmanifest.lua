fx_version 'cerulean'
game 'gta5'

author 'F4 Development'
description 'F4 Crafting System'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    'shared/shared.lua'
}

client_scripts {
    'client/client.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/server.lua'
}

ui_page 'ui/index.html'

files {
    'ui/index.html',
    'ui/style.css',
    'ui/script.js',
}

lua54 'yes'

