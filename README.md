# ZeroSpeech 2019 Eval with Run-Length Encoding

This repository contains scripts adapted from the ZeroSpeech 2019 challenge,
which we modified to compute ABX scores and bit-rates of discrete representations
based on **lossless/lossy run-length encoding (RLE)**.

Lossless RLE can achieve a even lower bit-rate without losing information. The
compression rate of RLE is higher when there are many long segments in the code
sequences. Hence, it can be used as a metric that penalizes fragmentation.

These numbers were reported in our recent work: 
[Learning Hierarchical Discrete Linguistic Units from Visually-Grounded Speech](https://openreview.net/forum?id=B1elCp4KwH),
demonstrating one of many benefits of learning discrete 
representations. Pre-trained models and codes of ResDAVEnet-VQ can be found in
this [repo](https://github.com/wnhsu/ResDAVEnet-VQ)

If you find the code useful, please cite
```
@inproceedings{Harwath2020Learning,
  title={Learning Hierarchical Discrete Linguistic Units from Visually-Grounded Speech},
  author={David Harwath and Wei-Ning Hsu and James Glass},
  booktitle={International Conference on Learning Representations},
  year={2020},
  url={https://openreview.net/forum?id=B1elCp4KwH}
}
```

## What is run-length encoding?
Let `z` be a discrete code sequence `[1, 1, 1, 1, 1, 3, 3, 2, 3, 3, 2, 2]`.

**Lossless run-length encoding** produces 
`z_lossless_rle = [(1,5), (3,2), (2,1), (3,2), (2,2)]`,
which is a sequence of (code, duration) tuples.

**Lossy run-length encoding** (segment encoding) produces 
`z_lossy_rle = [1, 3, 2, 3, 2]`


## How to use?
Users need to download the dataset and the Docker image by following the 
instructions [here](https://zerospeech.com/2019/getting_started.html). After 
entering the interactive session within the Docker machine, clone this repo by
running
```
git clone https://github.com/wnhsu/ZeroSpeech2019_RLE_eval
```

The entry script is `evaluate_rle.sh`, which is takes the same arguments as
the original evaluation script `evaluate.sh`. To evaluate a ZS19 submission,
run
```
bash evaluate_rle.sh <submission_zip> <which_embedding> <which_distance>
```
See the ZeroSpeech 2019 website for how to prepare a `submission_zip` file.


## Results explained
The results will be saved at `./<name>.{abx_frm,abx_seg,bitrate,bitrate_rle}.txt`

- `.abx_frm.txt`: standard ZS19 ABX test results on the original code sequences
- `.abx_seg.txt`: ABX test results on segments (converted using lossy RLE)
- `.bitrate.txt`: standard ZS19 bit-rate results on the original code sequences
- `.birate_rle.txt`:
  * `RLE bitrate`: bit-rate of lossless-RLE code sequences, which treats a (code,
    duration) as a symbol when computing `bits-per-segment`
  * `factored-RLE bitrate`: bit-rate of lossless-RLE code sequences, which
    computes bits-per-code and bits-per-duration separately, and estimates
    `bits-per-segment = bits-per-code + bits-per-duration`.
  * `segment bitrate`: bit-rate of lossy-RLE code sequence, which discards
    length information and reflects the bit-rate for segment-based ABX test
    results.
