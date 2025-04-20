#!/bin/bash

set -e

echo "🔄 Updating system..."
sudo apt update && sudo apt upgrade -y

echo "📦 Installing essentials..."
sudo apt install -y git curl wget unzip ca-certificates lsb-release gnupg zsh

echo "🧠 Installing Oh My Zsh..."
if [ ! -d "$HOME/.oh-my-zsh" ]; then
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
fi

echo "🎨 Installing Powerlevel10k..."
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k

echo "🔧 Setting Zsh as default shell..."
chsh -s $(which zsh)

echo "🔤 Installing MesloLGS Nerd Font (required for Powerlevel10k)..."
mkdir -p ~/.fonts
cd ~/.fonts
wget -q https://github.com/ryanoasis/nerd-fonts/releases/latest/download/Meslo.zip
unzip -o Meslo.zip && rm Meslo.zip
fc-cache -fv

echo "📁 Backing up existing .zshrc..."
[ -f ~/.zshrc ] && mv ~/.zshrc ~/.zshrc.backup

echo "🧾 Creating new .zshrc..."
cat << 'EOF' > ~/.zshrc
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="powerlevel10k/powerlevel10k"

plugins=(git docker kubectl terraform colored-man-pages command-not-found zsh-autosuggestions zsh-syntax-highlighting)

source $ZSH/oh-my-zsh.sh
[[ -f ~/.p10k.zsh ]] && source ~/.p10k.zsh

alias k="kubectl"
alias kgp="kubectl get pods"
alias kgs="kubectl get svc"
alias tf="terraform"
alias cls="clear"
alias ..="cd .."
alias ...="cd ../.."
alias dcu="docker compose up -d"
alias dcd="docker compose down"
alias ll="ls -lah --color=auto"

export PATH="$HOME/bin:/usr/local/bin:$PATH"

precmd () { print -Pn "\e]0;%n@%m: %~ (git:$(git rev-parse --abbrev-ref HEAD 2>/dev/null))\a" }
EOF

echo "🔌 Installing Zsh plugins..."
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting

echo "💻 Installing VS Code CLI support..."
sudo ln -sf /mnt/c/Users/$USER/AppData/Local/Programs/Microsoft\ VS\ Code/bin/code /usr/local/bin/code || true

echo "⚙️ Optional: Installing DevOps tools (comment out if not needed)..."
# AWS CLI
curl -s "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip && sudo ./aws/install && rm -rf aws awscliv2.zip

# kubectl
curl -LO "https://dl.k8s.io/release/$(curl -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl && rm kubectl

# Terraform
sudo apt-add-repository -y ppa:deadsnakes/ppa && sudo apt update
sudo apt install -y gnupg software-properties-common
wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install terraform -y

echo "✅ Done! Restart your terminal or run: exec zsh"
echo "🧠 Run p10k configure to set up your prompt!"
