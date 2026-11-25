// Link test suite on every platform and Dyalog version in CI/testmatrix; see TESTING.md.
// Runs nightly on master, on pushes to pull requests from Dyalog/link branches, and by hand. 

// Parse CI/testmatrix: [agents] "platform [version]" -> label, [versions] -> [platform, version] cells
def parseMatrix(String text) {
    def section = ''
    def agents = [:]
    def cells = []
    for (String raw : text.split('\n')) {
        def line = raw.replaceAll(/#.*/, '').trim()
        if (line == '') { continue }
        if (line.startsWith('[')) { section = line; continue }
        def fields = line.split(/\s+/)
        if (section == '[agents]') {
            def key = fields[0]
            def rest = line.substring(fields[0].length()).trim()
            if (fields.length > 1 && fields[1] ==~ /\d+\.\d+/) {   // version-specific, e.g. "aix 20.0 ..."
                key = fields[0] + ' ' + fields[1]
                rest = rest.substring(fields[1].length()).trim()
            }
            agents[key] = rest
        } else if (section == '[versions]') {
            cells << [platform: fields[0], version: fields[1]]
        }
    }
    return [agents: agents, cells: cells]
}

// Mail failures must not turn UNSTABLE into FAILURE
def notify(String subject, String body) {
    try {
        emailext to: 'link@dyalog.com', subject: subject, body: body, mimeType: 'text/plain'
    } catch (err) {
        echo "WARNING: could not send mail to link@dyalog.com (${err}) - the build result is not affected"
    }
}

// CI/runlinktests exit code: 0 passed, 1 tests failed, other could not run
def runTests(platform, version, tests) {
    int rc
    // pass arguments via the environment, never interpolated into the command (TESTS is user input)
    withEnv(["LINKTEST_PLATFORM=${platform}", "LINKTEST_VERSION=${version}", "LINKTEST_TESTS=${tests}"]) {
        if (platform == 'win') {
            rc = bat(returnStatus: true,
                     script: '"%CYGWIN_DIR%\\bin\\bash.exe" --login -c "cd \\"$(cygpath -u \\"$WORKSPACE\\")\\" && bash CI/runlinktests \\"$LINKTEST_PLATFORM\\" \\"$LINKTEST_VERSION\\" \\"$LINKTEST_TESTS\\""')
        } else {
            rc = sh(returnStatus: true, script: 'bash CI/runlinktests "$LINKTEST_PLATFORM" "$LINKTEST_VERSION" "$LINKTEST_TESTS"')
        }
    }
    if (rc == 1) {
        unstable("Link tests failed on ${platform} with Dyalog ${version}")
    } else if (rc != 0) {
        error("Could not run the Link tests on ${platform} with Dyalog ${version} (exit code ${rc})")
    }
}

pipeline {
    agent none
    parameters {
        string(name: 'TESTS', defaultValue: 'all', description: "Argument for ⎕SE.Link.RunTests: 'all', or the names of tests separated by spaces (e.g. test_add test_fix)")
        booleanParam(name: 'RUN_WIN',       defaultValue: true, description: 'Windows')
        booleanParam(name: 'RUN_MAC',       defaultValue: true, description: 'macOS (Intel)')
        booleanParam(name: 'RUN_MAC_ARM',   defaultValue: true, description: 'macOS (Apple Silicon)')
        booleanParam(name: 'RUN_LINUX',     defaultValue: true, description: 'Linux (x64, in Docker)')
        booleanParam(name: 'RUN_LINUX_ARM', defaultValue: true, description: 'Linux (arm64)')
        booleanParam(name: 'RUN_PI',        defaultValue: true, description: 'Raspberry Pi (arm32)')
        booleanParam(name: 'RUN_AIX',       defaultValue: true, description: 'AIX')
    }
    triggers {
        // nightly on master, after the interpreter builds
        cron(env.BRANCH_NAME == 'master' ? 'H 3 * * *' : '')
    }
    options {
        skipDefaultCheckout()
        disableConcurrentBuilds(abortPrevious: true)
        timeout(time: 3, unit: 'HOURS')
        buildDiscarder(logRotator(numToKeepStr: '50'))
    }
    stages {
        stage('Test') {
            steps {
                script {
                    // CHANGE_FORK is set only for fork PRs: refuse before anything reaches an agent
                    if (env.CHANGE_FORK) {
                        error("Pull request ${env.CHANGE_ID} comes from the fork ${env.CHANGE_FORK}: Jenkins does not build outside code on Dyalog's internal machines")
                    }
                    // TESTS ends up in an APL string: allow only names
                    if (!(params.TESTS ==~ /[A-Za-z0-9_]+( [A-Za-z0-9_]+)*/)) {
                        error("Invalid TESTS parameter '${params.TESTS}': 'all' or test names separated by spaces (letters, digits and _ only)")
                    }
                    def matrix = parseMatrix(readTrusted('CI/testmatrix'))
                    def branches = [:]
                    for (cell in matrix.cells) {
                        def platform = cell.platform
                        def version = cell.version
                        def label = matrix.agents[platform + ' ' + version] ?: matrix.agents[platform]
                        if (label == null) { continue }   // not a Jenkins platform
                        if (params["RUN_${platform.toUpperCase()}"] == false) { continue }
                        label = label.replace('{version}', version)
                        branches["${platform} ${version}"] = {
                            node(label) {
                                try {
                                    cleanWs()
                                    checkout scm
                                    runTests(platform, version, params.TESTS)
                                } finally {
                                    // archive first, so logs and aplcores survive a junit failure
                                    archiveArtifacts artifacts: 'results/**', allowEmptyArchive: true
                                    junit testResults: 'results/junit-*.xml', allowEmptyResults: true
                                }
                            }
                        }
                    }
                    parallel branches
                }
            }
        }
    }
    post {
        // mail only for the nightly master build
        unsuccessful {
            script {
                if (env.BRANCH_NAME == 'master') {
                    notify("Link tests ${currentBuild.currentResult}: ${env.JOB_NAME} #${env.BUILD_NUMBER}",
                           "${currentBuild.currentResult}: ${env.JOB_NAME} #${env.BUILD_NUMBER}\n\nTest results: ${env.BUILD_URL}testReport/\nConsole:      ${env.BUILD_URL}console\n")
                }
            }
        }
        fixed {
            script {
                if (env.BRANCH_NAME == 'master') {
                    notify("Link tests back to normal: ${env.JOB_NAME} #${env.BUILD_NUMBER}", "All Link tests pass again: ${env.BUILD_URL}\n")
                }
            }
        }
    }
}
