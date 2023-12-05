pushd ..
call bundle
call npm run build
call bundle exec jekyll s
popd
pause