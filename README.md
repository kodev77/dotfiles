### generate new rsa ssh key
ssh-keygen -t rsa -b 4096 -C "youremail@test.com"
cat ~/.ssh/id_rsa.pub

### start and add ssh key into agent
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_rsa

### symlink the local files to our repo version
ln -s ~/git-setup/.gitconfig ~/.gitconfig
ln -s ~/vim-setup/.vimrc ~/.vimrc
ln -s ~/vim-setup/.vim ~/.vim
