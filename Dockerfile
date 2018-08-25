# Run ChromeDriver Headless in a container
#
# This is a good alternative to running selenium standalone in the event you
# are experiencing network disconnects or other issues.
#
# Very heavily copied from:
#   https://github.com/justinribeiro/dockerfiles/tree/master/chrome-headless
#
# What's New
#
# 1. Pulls from Chrome Stable
# 2. You can now use the ever-awesome Jessie Frazelle seccomp profile for Chrome.
#     wget https://raw.githubusercontent.com/jfrazelle/dotfiles/master/etc/docker/seccomp/chrome.json -O ~/chrome.json
#
#
# To run (without seccomp):
# docker run -d -p 4444:4444 --cap-add=SYS_ADMIN voor/chromedriver-headless
#
# To run a better way (with seccomp):
# docker run -d -p 4444:4444 --security-opt seccomp=$HOME/chrome.json voor/chromedriver-headless
#
# Basic use: configure remote capability to http://localhost:4444/wd/hub
#
FROM debian:stretch-slim
LABEL name="chromedriver-headless" \
			maintainer="Robert Van Voorhees <rcvanvo@gmail.com>" \
			version="2.0" \
			description="Google ChromeDriver Headless in a container"

# Install deps + add Chrome Stable + ChromeDriver + purge all the things
RUN apt-get update && apt-get install -y \
	apt-transport-https \
	ca-certificates \
  unzip \
	curl \
	gnupg \
	--no-install-recommends \
	&& curl -sSL https://dl.google.com/linux/linux_signing_key.pub | apt-key add - \
	&& echo "deb [arch=amd64] https://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google-chrome.list \
	&& apt-get update && apt-get install -y \
	google-chrome-stable \
	--no-install-recommends \
  && curl -sSL https://chromedriver.storage.googleapis.com/2.41/chromedriver_linux64.zip -o /tmp/chromedriver_linux64.zip \
  && unzip -p /tmp/chromedriver_linux64.zip > /usr/local/bin/chromedriver \
  && chmod +x /usr/local/bin/chromedriver \
  && rm /tmp/chromedriver_linux64.zip \
	&& apt-get purge --auto-remove -y curl gnupg unzip \
	&& rm -rf /var/lib/apt/lists/*

# This allows easily passing default best-use arguments into ChromeDriver from capabilities
ENV CHROMEOPTIONS_ARGS '--headless --disable-gpu --disable-software-rasterizer'

# Add Chrome as a user
RUN groupadd -r chrome && useradd -r -g chrome -G audio,video chrome \
    && mkdir -p /home/chrome && chown -R chrome:chrome /home/chrome

# Run Chrome non-privileged
USER chrome

EXPOSE 4444

ENTRYPOINT [ "/usr/local/bin/chromedriver" ]
CMD [ "--port=4444", "--url-base=wd/hub", "--whitelisted-ips=" ]
