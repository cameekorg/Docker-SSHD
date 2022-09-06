@echo.
@echo Run SSH Server
@echo --------------

docker run -it ^
 -v shared-data:/shared/data ^
 -p 2231:22 ^
 --name ssh-server ^
 --hostname ssh-server ^
 cameek/sshd:0.3