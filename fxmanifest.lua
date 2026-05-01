fx_version 'cerulean'
game 'gta5'

lua54 'yes'

author 'Opie Winters'
description 'Simple business introduction directory with in-UI admin editing'
version '2.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua'
}

client_scripts {
    'client/main.lua'
}

server_scripts {
    'server/main.lua'
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/app.js',
    'data/businesses.json'
}

dependencies {
    'ox_lib',
    'qb-core'
}
