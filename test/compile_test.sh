#!/bin/sh

. ${BUILDPACK_TEST_RUNNER_HOME}/lib/test_utils.sh

WRAPPER_DIR=${BUILDPACK_HOME}/test/wrapper
  
installWrapper() {
  cp -r "$WRAPPER_DIR"/* ${BUILD_DIR}
}

testCompileWithoutWrapper()
{
  compile 
  assertCapturedError "'./gradlew' script not found - please enable the Gradle Wrapper for this project."
}

testCompileWithWrapper() 
{
  installWrapper
  expected_stage_output="STAGING:${RANDOM}"

  cat > ${BUILD_DIR}/build.gradle <<EOF
task stage << {
  println "${expected_stage_output}"
}
EOF

  compile
  assertCapturedSuccess
  assertCaptured "Installing OpenJDK 1.6" 
  assertCaptured "${expected_stage_output}" 
  assertCaptured "BUILD SUCCESSFUL"
  assertTrue "Java should be present in runtime." "[ -d ${BUILD_DIR}/.jdk ]"
  assertTrue "Java version file should be present." "[ -f ${BUILD_DIR}/.jdk/version ]"
  assertTrue "System properties file should be present in build dir." "[ -f ${BUILD_DIR}/system.properties ]" 
  assertTrue "Gradle profile.d file should be present in build dir." "[ -f ${BUILD_DIR}/.profile.d/gradle.sh ]"
  assertTrue "GRADLE_USER_HOME should be CACHE_DIR/.gradle." "[ -d ${CACHE_DIR}/.gradle ]"
}

testCompile_Fail()
{
  installWrapper
  expected_stage_output="STAGING:${RANDOM}"  
  
  cat > ${BUILD_DIR}/build.gradle <<EOF
task stage << {
  throw new GradleException("${expected_stage_output}")
}
EOF

  compile  
  assertCapturedError "${expected_stage_output}"
  assertCapturedError "BUILD FAILED"
}
