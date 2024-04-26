/*
 * Copyright (c) 2023-2024, NVIDIA CORPORATION.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

/*
 * NOTE: this file is generated by ivf_flat_00_generate.py
 *
 * Make changes there and run in this directory:
 *
 * > python ivf_flat_00_generate.py
 *
 */

#include <raft/neighbors/ivf_flat-inl.cuh>

#define instantiate_raft_neighbors_ivf_flat_search(T, IdxT)     \
  template void raft::neighbors::ivf_flat::search<T, IdxT>(     \
    raft::resources const& handle,                              \
    const raft::neighbors::ivf_flat::search_params& params,     \
    const raft::neighbors::ivf_flat::index<T, IdxT>& index,     \
    const T* queries,                                           \
    uint32_t n_queries,                                         \
    uint32_t k,                                                 \
    IdxT* neighbors,                                            \
    float* distances,                                           \
    std::optional<rmm::device_async_resource_ref> mr);          \
                                                                \
  template void raft::neighbors::ivf_flat::search<T, IdxT>(     \
    raft::resources const& handle,                              \
    const raft::neighbors::ivf_flat::search_params& params,     \
    const raft::neighbors::ivf_flat::index<T, IdxT>& index,     \
    raft::device_matrix_view<const T, IdxT, row_major> queries, \
    raft::device_matrix_view<IdxT, IdxT, row_major> neighbors,  \
    raft::device_matrix_view<float, IdxT, row_major> distances);
instantiate_raft_neighbors_ivf_flat_search(int8_t, int64_t);

#undef instantiate_raft_neighbors_ivf_flat_search
