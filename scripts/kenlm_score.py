import sys
import kenlm

model_name = sys.argv[1]
test_name = sys.argv[2]
model = kenlm.LanguageModel(model_name)
scores=[]
lines = [line.strip().lower() for line in open(test_name, "r").readlines()]
for line in lines:
	try:
		print(model.score(line)/len(line.split(" ")))
	except:
		print(f"Possible division by zero: {line}")
"""
normalized by length - The reason that we need to normalize for length is that
the value of log(P(s|I)) − log(P(s|N)) tends to
correlate very strongly with text segment length.
If the candidate text segments vary greatly in
length—e.g., if we partition N into sentences—
this correlation can be a serious problem

To Do:

To further increase the comparability of these
Europarl and Gigaword language models, we restricted the vocabulary of both models to the tokens appearing at least twice in the Europarl training data, treating all other tokens as instances of
<UNK>.
"""
