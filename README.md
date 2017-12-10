# twenty48

* https://github.com/jdleesmiller/twenty48

## SYNOPSIS

**Research-quality code** for studying 2048. The code in this repo backs what will be a series of blog posts:

### 1. Minimum Moves to Win with Markov Chains

Blog post: http://jdlm.info/articles/2017/08/05/markov-chain-2048.html

Files:

- `bin/markov_chain` --- generates most of the data
- `data/markov_chain/plot.R` --- scripts to create the plots

### 2. Number of States with Combinatorics

Blog post: http://jdlm.info/articles/2017/09/17/counting-states-combinatorics-2048.html

Files:

- `bin/combinatorics` --- generates the data
- `bin/combinatorics_summary` --- aggregation for the blog post
- `data/combinatorics/plot_layers.R` --- plot for the layer state counts
- `data/combinatorics/plot_totals.R` --- plot for the total state counts

### 3. Number of States by Exhaustive Enumeration

Blog post: http://jdlm.info/articles/2017/12/10/counting-states-enumeration-2048.html

Files:

- `bin/enumeration` --- utilities
- `data/enumeration/enumeration.Rmd` --- plots
- `ext/twenty48/layer_builder.hpp` --- main enumeration class
- `ext/twenty48/state.hpp` --- main state class for bit bashing

## LICENSE

(The MIT License)

Copyright (c) 2016-2017 John Lees-Miller

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
'Software'), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
