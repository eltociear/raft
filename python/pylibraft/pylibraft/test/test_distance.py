# Copyright (c) 2022, NVIDIA CORPORATION.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

import numpy as np
import pytest
from scipy.spatial.distance import cdist

from pylibraft.common import Handle, device_ndarray
from pylibraft.distance import pairwise_distance


@pytest.mark.parametrize("n_rows", [100])
@pytest.mark.parametrize("n_cols", [100])
@pytest.mark.parametrize(
    "metric",
    [
        "euclidean",
        "cityblock",
        "chebyshev",
        "canberra",
        "correlation",
        "hamming",
        "jensenshannon",
        "russellrao",
        "cosine",
        "sqeuclidean",
    ],
)
@pytest.mark.parametrize("inplace", [True, False])
@pytest.mark.parametrize("order", ["F", "C"])
@pytest.mark.parametrize("dtype", [np.float32, np.float64])
def test_distance(n_rows, n_cols, inplace, metric, order, dtype):
    input1 = np.random.random_sample((n_rows, n_cols))
    input1 = np.asarray(input1, order=order).astype(dtype)

    # RussellRao expects boolean arrays
    if metric == "russellrao":
        input1[input1 < 0.5] = 0
        input1[input1 >= 0.5] = 1

    # JensenShannon expects probability arrays
    elif metric == "jensenshannon":
        norm = np.sum(input1, axis=1)
        input1 = (input1.T / norm).T

    output = np.zeros((n_rows, n_rows), dtype=dtype)

    expected = cdist(input1, input1, metric)

    expected[expected <= 1e-5] = 0.0

    input1_device = device_ndarray(input1)
    output_device = device_ndarray(output) if inplace else None

    handle = Handle()
    ret_output = pairwise_distance(
        input1_device, input1_device, output_device, metric
    )
    handle.sync()

    output_device = ret_output if not inplace else output_device

    actual = output_device.copy_to_host()

    actual[actual <= 1e-5] = 0.0

    assert np.allclose(expected, actual, rtol=1e-4)
