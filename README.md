```python
import bs4
from bs4 import BeautifulSoup
import requests
import re
```

Check the version of `BeautifulSoup` package


```python
bs4.__version__
```




    '4.12.3'



Get the main page of the dataset of interest


```python
source = 'https://data.nemoarchive.org/biccn/grant/u01_lein/linnarsson/transcriptome/sncell/10x_v3/human/raw/'
r = requests.get(source)
```

Parse a main page with `BeautifulSoup` to get all sample names


```python
doc = BeautifulSoup(r.text, 'html.parser')
```

Get sample names of interest from file


```python
with open('run_list.txt', 'r') as f:
    samples = [line.rstrip() for line in f.readlines()]
samples[:5]
```




    ['10X145-3', '10X145-4', '10X145-5', '10X145-6', '10X146-2']



Parse `.fastq` links for each sample


```python
sample_list = []

for sample in samples:
    tag = doc.find(string=re.compile(f"({sample}).*"))
    if 'fastq' not in tag:
        sample_r = requests.get(source + tag)
        sample_doc = BeautifulSoup(sample_r.text, 'html.parser')
        dirs = [tag.a.text for tag in sample_doc.find_all('tr') if tag.img and tag.img['alt'] == '[DIR]']
        for dir in dirs:
            run_r = requests.get(source + tag + dir)
            run_doc = BeautifulSoup(run_r.text, 'html.parser')
            runs = run_doc.find_all(string=re.compile(f"({sample}).*fastq.tar"))
            for run in runs:
                sample_dict = {
                    'sample': sample,
                    'filename': run.replace('-', '_'),
                    'link': source + tag.text + dir + run.text
                }
                sample_list.append(sample_dict)
    else:
        sample_dict = {
                    'sample': sample,
                    'filename': tag.text.replace('-', '_'),
                    'link': source + tag.text
                }
        sample_list.append(sample_dict)
        
```

Save results to file


```python
import pandas as pd

df = pd.DataFrame(sample_list)
df['is_duplicate'] = ((~df.duplicated(subset=['sample', 'filename'], keep='first')) & df.duplicated(subset=['sample', 'filename'], keep=False))
df['duplicate_number'] = df.groupby(['sample', 'filename']).cumcount() + 1
df.loc[df['is_duplicate'], 'sample'] = df['sample'] + '-' + df['duplicate_number'].astype(str)
df[df['is_duplicate']]
```




<div>
<table border="1" class="dataframe">
  <thead>
    <tr style="text-align: right;">
      <th></th>
      <th>sample</th>
      <th>filename</th>
      <th>link</th>
      <th>is_duplicate</th>
      <th>duplicate_number</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <th>111</th>
      <td>10X215-6-1</td>
      <td>10X215_6_S6_L001.fastq.tar</td>
      <td>https://data.nemoarchive.org/biccn/grant/u01_l...</td>
      <td>True</td>
      <td>1</td>
    </tr>
    <tr>
      <th>112</th>
      <td>10X215-6-1</td>
      <td>10X215_6_S6_L002.fastq.tar</td>
      <td>https://data.nemoarchive.org/biccn/grant/u01_l...</td>
      <td>True</td>
      <td>1</td>
    </tr>
    <tr>
      <th>119</th>
      <td>10X216-7-1</td>
      <td>10X216_7_S15_L003.fastq.tar</td>
      <td>https://data.nemoarchive.org/biccn/grant/u01_l...</td>
      <td>True</td>
      <td>1</td>
    </tr>
    <tr>
      <th>120</th>
      <td>10X216-7-1</td>
      <td>10X216_7_S15_L004.fastq.tar</td>
      <td>https://data.nemoarchive.org/biccn/grant/u01_l...</td>
      <td>True</td>
      <td>1</td>
    </tr>
  </tbody>
</table>
</div>




```python
df_to_csv = df[['sample', 'filename', 'link']]
df_to_csv.to_csv('sample_list.tsv', index=False, sep='\t', header=False)
```
