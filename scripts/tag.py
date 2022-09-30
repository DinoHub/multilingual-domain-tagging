import argparse

def tag(file2tag_name, tags_name, tagged_file_name):
    lines2tag = open(file2tag_name, "r").readlines()
    tagged_file = open(tagged_file_name, "w")
    tags = [ tag.strip() for tag in open(tags_name).readlines()]

    assert len(tags) == len(lines2tag), "Files should be the same size"
    for i in range(len(tags)):
        tagged_file.write(tags[i] + " " + lines2tag[i])

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--file2tag", type=str)
    parser.add_argument("--tags", type=str)
    parser.add_argument("--tagged_file", type=str)
    args = parser.parse_args()

    tag(args.file2tag, args.tags, args.tagged_file)

if __name__=="__main__":
        main()