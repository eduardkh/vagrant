echo "configure docker"
sudo usermod -aG docker $USER
mkdir -p ~/.docker/completions
docker completion zsh > ~/.docker/completions/_docker
echo "configure docker - Done"