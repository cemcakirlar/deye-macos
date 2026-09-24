.DEFAULT_GOAL := help
.PHONY: all run run-fg stop build release install logs clean help

all: help

# Uygulamayı arka planda derleyip başlatır (Debug)
run:
	@./scripts/run.sh

# Uygulamayı terminal ön planında çalıştırır (Konsol loglarını görmek için)
run-fg:
	@./scripts/run.sh --foreground

# Çalışan uygulamayı sonlandırır
stop:
	@./scripts/stop.sh

# Debug derlemesi yapar
build:
	@./scripts/build.sh --debug

# Prod (Release) derlemesi yapar
release:
	@./scripts/build.sh --release

# Prod sürümü derler ve macOS /Applications dizinine kurar
install:
	@./scripts/install.sh --release

# Canlı sistem loglarını dinler
logs:
	@./scripts/logs.sh

# Derleme önbelleğini temizler
clean:
	@./scripts/build.sh --clean

# Yardım menüsü
help:
	@echo "Deye Solar Monitor - Geliştirici Komutları:"
	@echo "  make run       : Debug derlemesi yapıp uygulamayı başlatır (Varsayılan)"
	@echo "  make run-fg    : Terminalde canlı loglarla ön planda çalıştırır"
	@echo "  make stop      : Çalışan uygulamayı sonlandırır"
	@echo "  make build     : Sadece Debug modunda derler"
	@echo "  make release   : Sadece Release (Prod) modunda derler"
	@echo "  make install   : Release derleyip /Applications altına kalıcı olarak kurar"
	@echo "  make logs      : Canlı sistem loglarını dinler"
	@echo "  make clean     : Derleme önbelleğini temizler"
