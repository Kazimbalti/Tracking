/*
 * Copyright (c) 2017, The Regents of the University of California (Regents).
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met:
 *
 *    1. Redistributions of source code must retain the above copyright
 *       notice, this list of conditions and the following disclaimer.
 *
 *    2. Redistributions in binary form must reproduce the above
 *       copyright notice, this list of conditions and the following
 *       disclaimer in the documentation and/or other materials provided
 *       with the distribution.
 *
 *    3. Neither the name of the copyright holder nor the names of its
 *       contributors may be used to endorse or promote products derived
 *       from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS AS IS
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
 * LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 *
 * Please contact the author(s) of this library if you have any questions.
 * Authors: David Fridovich-Keil   ( dfk@eecs.berkeley.edu )
 */

///////////////////////////////////////////////////////////////////////////////
//
// Defines the SubsystemValueFunction class.
//
///////////////////////////////////////////////////////////////////////////////

#ifndef META_PLANNER_SUBSYSTEM_VALUE_FUNCTION_H
#define META_PLANNER_SUBSYSTEM_VALUE_FUNCTION_H

#include <meta_planner/dynamics.h>
#include <meta_planner/types.h>
#include <meta_planner/uncopyable.h>

#include <ros/ros.h>
#include <matio.h>
#include <math.h>
#include <memory>

namespace meta {

class SubsystemValueFunction : private Uncopyable {
public:
  typedef std::unique_ptr<const SubsystemValueFunction> ConstPtr;

  // Destructor.
  ~SubsystemValueFunction() {}

  // Factory method. Use this instead of the constructor.
  // Note that this class is const-only, which means that once it is
  // instantiated it can never be changed.
  static ConstPtr Create(const std::string& file_name);

  // Linearly interpolate to get the value/gradient at a particular state.
  double Value(const VectorXd& state) const;
  VectorXd Gradient(const VectorXd& state) const;

  // Get the tracking error bound.
  inline double TrackingBound() const { return tracking_bound_; }

  // Was this SubsystemValueFunction properly initialized?
  inline bool IsInitialized() const { return initialized_; }

private:
  explicit SubsystemValueFunction(const std::string& file_name);

  // Puncture a state vector for the overall system to get a
  // valid state vector for this subsystem.
  VectorXd Puncture(const VectorXd& state) const;

  // Return the 1D voxel index corresponding to the given state.
  size_t StateToIndex(const VectorXd& state) const;

  // Compute the distance (vector) from this state to the center
  // of the nearest voxel.
  VectorXd DistanceToCenter(const VectorXd& state) const;

  // Compute a central difference at the voxel containing this state.
  VectorXd CentralDifference(const VectorXd& state) const;

  // Load from file. Returns whether or not it was successful.
  bool Load(const std::string& file_name);

  // Which dimensions in the full state/control space does this
  // value grid correspond to?
  std::vector<size_t> state_dimensions_;
  std::vector<size_t> control_dimensions_;

  // Number of voxels and upper/lower bounds in each dimension.
  std::vector<size_t> num_voxels_;
  std::vector<double> voxel_size_;
  std::vector<double> lower_;
  std::vector<double> upper_;

  // Data is stored in row-major order.
  std::vector<double> data_;

  // Tracking error bound.
  double tracking_bound_;

  // Was this value function initialized/loaded properly?
  bool initialized_;
};

} //\namespace meta

#endif
