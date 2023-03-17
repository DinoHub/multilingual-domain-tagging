import os
import explainaboard_client

# Set up your environment
explainaboard_client.username = "aogayo@andrew.cmu.edu"
explainaboard_client.api_key = "wFudu8JFs5VPYbRs5ITK_A"
client = explainaboard_client.ExplainaboardClient()

# Do the evaluation
evaluation_result = client.evaluate_system_file(
    task="machine-translation",
    system_name="llm_best",
    system_output_file="llmbes_preds.txt",
    system_output_file_type="text",
    source_language="mya",
    custom_dataset_file="test_my-en.tsv",
    custom_dataset_file_type="tsv",
    split="",
    metric_names=["bleu","comet"],
    target_language="eng",
    system_tags=["version-1"]
)
