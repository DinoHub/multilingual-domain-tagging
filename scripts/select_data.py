import numpy as np
from sklearn.model_selection import train_test_split
import sys

f_name = sys.argv[1]
select_size = sys.argv[2]

lines = open(f_name, 'r').readlines()
select_p= int(select_size)/len(lines)
print("select % : "+str(select_p))
others, selected = train_test_split(lines, test_size=select_p, random_state=42)


def write_files(lines, out_file):
	for line in lines:
		out_file.write(line)
	out_file.close()

write_files(others, open(f_name+'.others', "w"))
write_files(selected, open(f_name+".selected", "w"))
print("Doneeeeee!!!!")
