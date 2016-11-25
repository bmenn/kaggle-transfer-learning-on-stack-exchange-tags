# Requires presence of credentials.txt file containing login/password in the following format:
# UserName=my_username&Password=my_password

COMPETITION=transfer-learning-on-stack-exchange-tags
KAGGLE_URL=http://www.kaggle.com/c/${COMPETITION}
DATA_FILES=$(shell cat files.txt | rev | cut -f 1 -d "/" | rev | sed "s/^/files\//")

all: download_files

session.cookie: credentials.txt
	curl -c session.cookie https\://www.kaggle.com/account/login
	curl -c session.cookie -b session.cookie -L -d @credentials.txt https\://www.kaggle.com/account/login

files.txt: session.cookie
	curl -c session.cookie -b session.cookie -L http\://www.kaggle.com/c/$(COMPETITION)/data | \
	grep -o \"[^\"]*\/download[^\"]*\" | sed -e 's/"//g' -e 's/^/http:\/\/www.kaggle.com/' > files.txt

download_files: files.txt session.cookie
	mkdir -p files
	cd files && xargs -n 1 curl --limit-rate 1M -b ../session.cookie -L -O < ../files.txt

files/%.zip:

extract: ${DATA_FILES}
	mkdir -p data/raw
	for f in ${DATA_FILES}; do unzip $${f} -d data/raw; done
	# for f in ${DATA_FILES}; do echo $$(basename $${f}); done

.PHONY: clean

clean:
	rm session.cookie files.txt files/*.zip
