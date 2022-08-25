import sys
import nltk
nltk.download('punkt')
f_name=sys.argv[1]
f=open(f_name, 'r')
for line in f.readlines():
    #for sentence in nltk.sent_tokenize(line):
        #print(line)
        #print(sentence)
        print(' '.join(nltk.word_tokenize(line)).lower())
