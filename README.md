### generate new rsa ssh key
```
ssh-keygen -t rsa -b 4096 -C "youremail@test.com"
cat ~/.ssh/id_rsa.pub
```

### start and add ssh key into agent
```
eval "$(ssh-agent -s)"
chmod 600 ~/.ssh/id_rsa
ssh-add ~/.ssh/id_rsa
```

### symlink the local files to our repo version
```
ln -s ~/repo/ko/dotfiles/.gitconfig ~/.gitconfig
ln -s ~/repo/ko/dotfiles/.vimrc ~/.vimrc
ln -s ~/repo/ko/dotfiles/.vim ~/.vim
```

### TODO LIST - add these to the config init script
- wmctrl

