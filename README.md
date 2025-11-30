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
### allow mysql in Windows Firewall
PowerShell - firewall
```
New-NetFirewallRule -DisplayName "Allow ICMPv4-In" -Protocol ICMPv4 -IcmpType 8 -Direction Inbound -Action Allow
```
MySql - user
```
CREATE USER 'root'@'172.27.%' IDENTIFIED BY 'BestRock1234';
GRANT ALL PRIVILEGES ON *.* TO 'root'@'172.27.%' WITH GRANT OPTION;
FLUSH PRIVILEGES;
```
