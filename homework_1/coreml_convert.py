import ssl
ssl._create_default_https_context = ssl._create_unverified_context

import torch
import torchvision
import torch.nn as nn
import coremltools as ct
import urllib.request
import json

labels_url = "https://raw.githubusercontent.com/anishathalye/imagenet-simple-labels/master/imagenet-simple-labels.json"
with urllib.request.urlopen(labels_url) as response:
    labels = json.loads(response.read().decode())

base_model = torchvision.models.mobilenet_v2(weights="IMAGENET1K_V1")
base_model.eval()

model = nn.Sequential(
    base_model,
    nn.Softmax(dim=1)
)

example_input = torch.rand(1, 3, 224, 224)
traced_model = torch.jit.trace(model, example_input)

mlmodel = ct.convert(
    traced_model,
    inputs=[
        ct.ImageType(
            name="image",
            shape=(1, 3, 224, 224),
            scale=1 / 255.0
        )
    ],
    classifier_config=ct.ClassifierConfig(
        class_labels=labels,
        predicted_feature_name="classLabel"
    ),
    compute_precision=ct.precision.FLOAT32
)

mlmodel.save("PythonConvertModel.mlpackage")
