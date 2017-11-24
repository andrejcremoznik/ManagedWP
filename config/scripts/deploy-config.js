module.exports = {
  defaultDeployEnv: 'production',
  deployEnvSSH: {
    production: {
      host: 'domain.tld',
      port: 22,
      username: 'user',
      agent: process.env.SSH_AUTH_SOCK
    }
  },
  deployEnvPaths: {
    production: '/srv/http/domain.tld/releases'
  }
}
