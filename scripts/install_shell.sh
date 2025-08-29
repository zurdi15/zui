#!/bin/bash
# ZUI Shell Installation Script
# Optional shell configuration and tools installation

set -euo pipefail

# Configuration
BASE_PATH=${BASE_PATH:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}
ZUI_PATH=${ZUI_PATH:-${HOME}/.zui}
TMP_PATH=${TMP_PATH:-/tmp/zui}
LOG_FILE="${TMP_PATH}/install_shell.log"

# Ensure log directory exists
mkdir -p "${TMP_PATH}"

# Imports
source "${BASE_PATH}/scripts/functions/logger.sh"
source "${BASE_PATH}/scripts/functions/colors.sh"
source "${BASE_PATH}/scripts/functions/command_utils.sh"

# Check if user wants shell configuration
confirm_shell_installation() {
	log_warn "Note: This will modify your shell configuration."
	log_warn "If you already have a customized shell setup, you may want to skip this."
	echo ""

	read -p "Install shell configuration? [y/N]: " -n 1 -r
	echo -e "\n"

	if [[ ! ${REPLY} =~ ^[Yy]$ ]]; then
		log_info "Shell installation skipped by user choice."
		exit 0
	fi
}

# Install shell configurations
install_shell_configs() {
	log_info "Installing shell configurations"

	# Ensure shell config directories exist (may have been created in main)
	if ! run_with_progress "- Ensuring shell configuration directories exist" mkdir -p "${ZUI_PATH}/shell" "${ZUI_PATH}/backups/shell"; then
		log_error "Failed to create shell directories"
		exit 1
	fi

	# Copy shell configuration files if they exist
	if [[ -d "${BASE_PATH}/shell" ]]; then
		if [[ -f "${BASE_PATH}/shell/.zshrc" ]]; then
			if ! run_with_progress "- Installing .zshrc" cp "${BASE_PATH}/shell/.zshrc" "${ZUI_PATH}/shell/"; then
				log_warn "Failed to copy .zshrc"
			fi
		else
			log_warn ".zshrc not found in ${BASE_PATH}/shell"
		fi
		if [[ -f "${BASE_PATH}/shell/.p10k.zsh" ]]; then
			if ! run_with_progress "- Installing .p10k.zsh" cp "${BASE_PATH}/shell/.p10k.zsh" "${ZUI_PATH}/shell/"; then
				log_warn "Failed to copy .p10k.zsh"
			fi
		else
			log_warn ".p10k.zsh not found in ${BASE_PATH}/shell"
		fi
	fi

	# Backup existing configs if they exist
	if [[ -f "${HOME}/.zshrc" && ! -L "${HOME}/.zshrc" ]]; then
		if ! run_with_progress "- Backing up existing .zshrc" cp "${HOME}/.zshrc" "${ZUI_PATH}/backups/shell/.zshrc"; then
			log_warn "Failed to backup existing .zshrc"
		fi
	fi

	if [[ -f "${HOME}/.p10k.zsh" && ! -L "${HOME}/.p10k.zsh" ]]; then
		if ! run_with_progress "- Backing up existing .p10k.zsh" cp "${HOME}/.p10k.zsh" "${ZUI_PATH}/backups/shell/.p10k.zsh"; then
			log_warn "Failed to backup existing .p10k.zsh"
		fi
	fi

	# Create symlinks to ZUI shell configs
	if [[ -f "${ZUI_PATH}/shell/.zshrc" ]]; then
		if ! run_with_progress "- Creating .zshrc symlink" ln -sfn "${ZUI_PATH}/shell/.zshrc" "${HOME}/.zshrc"; then
			log_warn "Failed to create .zshrc symlink"
		fi
	fi

	if [[ -f "${ZUI_PATH}/shell/.p10k.zsh" ]]; then
		if ! run_with_progress "- Creating .p10k.zsh symlink" ln -sfn "${ZUI_PATH}/shell/.p10k.zsh" "${HOME}/.p10k.zsh"; then
			log_warn "Failed to create .p10k.zsh symlink"
		fi
	fi

	# Install vim-plug for neovim
	if [[ ! -f "${HOME}/.local/share/nvim/site/autoload/plug.vim" ]]; then
		if ! run_with_progress "- Installing vim-plug for neovim" bash -c "curl -fLo '${HOME}/.local/share/nvim/site/autoload/plug.vim' --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim"; then
			log_warn "Failed to install vim-plug"
		fi
	fi

	# Copy vim configuration
	if [[ -d "${BASE_PATH}/core/.vim" ]]; then
		if ! run_with_progress "- Installing vim configuration" cp -r "${BASE_PATH}/core/.vim" "${HOME}/.vim"; then
			log_warn "Failed to copy vim config"
		fi
	fi
	echo ""
}

# Install zsh plugins
install_zsh_plugins() {
	log_info "Installing zsh plugins"

	# Create zsh plugins directory
	if ! run_with_progress "- Creating zsh plugins directory" sudo mkdir -p /usr/share/zsh/zsh-plugins; then
		log_error "Failed to create zsh plugins directory"
		exit 1
	fi

	# Install plugins (remove existing and clone in single command)
	if ! run_with_progress "- Installing zsh-syntax-highlighting" bash -c "sudo rm -rf /usr/share/zsh/zsh-plugins/zsh-syntax-highlighting && sudo git clone --quiet https://github.com/zsh-users/zsh-syntax-highlighting.git /usr/share/zsh/zsh-plugins/zsh-syntax-highlighting"; then
		log_warn "Failed to install zsh-syntax-highlighting"
	fi

	if ! run_with_progress "- Installing zsh-autosuggestions" bash -c "sudo rm -rf /usr/share/zsh/zsh-plugins/zsh-autosuggestions && sudo git clone --quiet https://github.com/zsh-users/zsh-autosuggestions /usr/share/zsh/zsh-plugins/zsh-autosuggestions"; then
		log_warn "Failed to install zsh-autosuggestions"
	fi

	if ! run_with_progress "- Installing zsh-autocomplete" bash -c "sudo rm -rf /usr/share/zsh/zsh-plugins/zsh-autocomplete && sudo git clone --quiet https://github.com/marlonrichert/zsh-autocomplete.git /usr/share/zsh/zsh-plugins/zsh-autocomplete"; then
		log_warn "Failed to install zsh-autocomplete"
	fi
	echo ""
}

# Install additional shell tools
install_shell_tools() {
	log_info "Installing shell tools"

	# Install zsh first
	if ! run_with_progress "- Installing zsh" sudo apt install -y zsh; then
		log_error "Failed to install zsh"
		exit 1
	fi

	if ! run_with_progress "- Installing lsd (LSDeluxe)" sudo apt install -y lsd; then
		log_error "Failed to install lsd"
		exit 1
	fi

	if ! run_with_progress "- Installing bat (A cat clone with wings)" sudo apt install -y bat; then
		log_error "Failed to install bat"
		exit 1
	fi

	if ! run_with_progress "- Installing ranger (Vim-like file manager)" sudo apt install -y ranger; then
		log_error "Failed to install ranger"
		exit 1
	fi

	if ! run_with_progress "- Installing neovim and plugins" bash -c "sudo apt install -y neovim && nvim +PlugInstall +qall 2>/dev/null || true"; then
		log_error "Failed to install neovim"
		exit 1
	fi

	# Install fzf (fuzzy finder)
	if ! run_with_progress "- Installing fzf (fuzzy finder)" bash -c "rm -rf '${HOME}/.fzf' && git clone --quiet --depth 1 https://github.com/junegunn/fzf.git '${HOME}/.fzf' && echo -e 'y\ny\ny\n' | '${HOME}/.fzf/install' >/dev/null"; then
		log_warn "Failed to install fzf"
	fi
	echo ""
}

configure_prompt() {
	log_info "Configure shell prompt"

	# Install omz
	if [[ ! -d "${HOME}/.oh-my-zsh" ]]; then
		if ! run_with_progress "- Installing Oh My Zsh" bash -c "RUNZSH=no CHSH=no sh -c \"\$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)\""; then
			log_warn "Failed to install Oh My Zsh"
		fi
	else
		log_info "- Oh My Zsh already exists, skipping..."
	fi
	if [[ ! -d "${ZSH_CUSTOM:-${HOME}/.oh-my-zsh/custom}/themes/powerlevel10k" ]]; then
		if ! run_with_progress "- Installing Powerlevel10k" git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "${ZSH_CUSTOM:-${HOME}/.oh-my-zsh/custom}/themes/powerlevel10k"; then
			log_warn "Failed to install Powerlevel10k"
		fi
	else
		log_info "- Powerlevel10k already exists, skiping..."
	fi
	echo ""

}

set_default_shell() {
	log_info "Setting zsh as default shell"

	# Check if zsh is installed
	if ! command -v zsh &>/dev/null; then
		log_error "Zsh is not installed. This should not happen - please check the installation."
		return 1
	fi

	# Verify zsh path exists
	if [[ ! -f "/usr/bin/zsh" ]]; then
		log_error "Zsh executable not found at /usr/bin/zsh"
		return 1
	fi

	# Change default shell for user
	if [[ ${SHELL} != *"zsh"* ]]; then
		if ! run_with_progress "- Changing default shell to zsh for user" sudo usermod --shell /usr/bin/zsh "${USER}"; then
			log_warn "Failed to change user shell to zsh"
		fi
	else
		log_info "User shell is already zsh"
	fi
	echo ""
}

# Configure root environment
# configure_root_environment() {
# 	log_info "Configuring root shell environment..."

# 	# Create root symlinks for shell configs
# 	if [[ -f "${ZUI_PATH}/shell/.zshrc" ]]; then
# 		sudo ln -sfn "${ZUI_PATH}/shell/.zshrc" /root/.zshrc ||
# 			log_warn "Failed to create root .zshrc symlink"
# 	fi

# 	if [[ -f "${ZUI_PATH}/shell/.p10k.zsh" ]]; then
# 		sudo ln -sfn "${ZUI_PATH}/shell/.p10k.zsh" /root/.p10k.zsh ||
# 			log_warn "Failed to create root .p10k.zsh symlink"
# 	fi

# 	# Copy root profile if it exists
# 	if [[ -f "${BASE_PATH}/redist/root/.profile" ]]; then
# 		sudo cp "${BASE_PATH}/redist/root/.profile" /root/ ||
# 			log_warn "Failed to copy root profile"
# 	fi

# 	log_success "Root shell environment configured"
# }

# Main installation function
main() {
	echo -e "${CYAN}╭─────────────────────────────────────────────────────────╮${NC}"
    echo -e "${CYAN}│                 ${GREEN}ZUI Shell Installation${CYAN}                  │${NC}"
    echo -e "${CYAN}╰─────────────────────────────────────────────────────────╯${NC}"

	# Check if ZUI is installed
	if [[ ! -d ${ZUI_PATH} ]]; then
		log_warn "ZUI core installation not found at: ${ZUI_PATH}"
		log_warn "Creating ZUI directory structure for shell installation only"
		log_warn "Some features may not be available without core installation"

		# Create basic ZUI directory structure
		if ! mkdir -p "${ZUI_PATH}/shell" "${ZUI_PATH}/backups/shell"; then
			log_error "Failed to create ZUI directory structure"
			exit 1
		fi
		echo ""
	fi

	confirm_shell_installation
	authenticate_sudo

	configure_prompt
	install_shell_configs
	install_zsh_plugins
	install_shell_tools
	set_default_shell

	log_info "${BLUE}Installation log:${NC} ${LOG_FILE}\n"
	log_info "Shell installation completed successfully!"
	log_info "Please restart your shell or run 'exec zsh' to use the new configuration."
}

# Run main function if script is executed directly
if [[ ${BASH_SOURCE[0]} == "${0}" ]]; then
	main "$@"
fi
