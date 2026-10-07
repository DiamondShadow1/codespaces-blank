fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'Copilot'
description 'bergischland_cctv - CCTV and surveillance system for FiveM ESX servers'
version '1.0.0'

shared_scripts {
    'config.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/*.lua'
}

client_scripts {
    'client/*.lua'
}

ui_page 'nui/index.html'

files {
    'nui/index.html',
    'nui/style.css',
    'nui/app.js',
    'nui/assets/**'
}

dependencies {
    'es_extended',
    'oxmysql'
}
