flutter build web --base-href "/" --no-tree-shake-icons

mkdir -p ../fluttron_host/assets/www

cp -r build/web/* ../fluttron_host/assets/www/