const { Client } = require('ssh2');
const fs = require('fs');
const path = require('path');

const conn = new Client();
const localDir = process.cwd();
const remoteDir = '/home/ubuntu/livechat';

const ignoreList = ['node_modules', '.git', '.next', 'deploy.js', 'package-lock.json'];

conn.on('ready', () => {
  console.log('Client :: ready');
  
  conn.exec(`mkdir -p ${remoteDir}`, (err, stream) => {
    if (err) throw err;
    stream.on('close', () => {
      conn.sftp((err, sftp) => {
        if (err) throw err;

        function walkSync(dir, filelist = []) {
          fs.readdirSync(dir).forEach(file => {
            if (ignoreList.includes(file)) return;
            const dirFile = path.join(dir, file);
            if (fs.statSync(dirFile).isDirectory()) {
              filelist = walkSync(dirFile, filelist);
            } else {
              filelist.push(dirFile);
            }
          });
          return filelist;
        }

        const files = walkSync(localDir);
        let uploaded = 0;

        function uploadNext() {
          if (uploaded >= files.length) {
            console.log('Upload complete! Running install scripts...');
            runInstall();
            return;
          }

          const localFile = files[uploaded];
          const relativePath = path.relative(localDir, localFile);
          const remoteFile = `${remoteDir}/${relativePath.replace(/\\/g, '/')}`;
          const remoteFileDir = remoteFile.substring(0, remoteFile.lastIndexOf('/'));

          conn.exec(`mkdir -p "${remoteFileDir}"`, (err, stream) => {
            stream.on('close', () => {
              sftp.fastPut(localFile, remoteFile, (err) => {
                if (err) {
                  console.error('Error uploading ' + localFile + ': ' + err.message);
                } else {
                  console.log(`Uploaded ${uploaded + 1}/${files.length}: ${relativePath}`);
                }
                uploaded++;
                uploadNext();
              });
            });
          });
        }

        console.log(`Uploading ${files.length} files...`);
        uploadNext();
      });
    });
  });
}).connect({
  host: '91.134.140.50',
  port: 22,
  username: 'ubuntu',
  password: 'Z7gZASZZBRqt'
});

function runInstall() {
  const pass = 'Z7gZASZZBRqt';
  const sudoCmd = (cmd) => `echo "${pass}" | sudo -S bash -c "${cmd}"`;

  const commands = [
    sudoCmd(`mkdir -p /var/www/livechat`),
    sudoCmd(`cp -r ${remoteDir}/* /var/www/livechat/`),
    sudoCmd(`cp ${remoteDir}/.env.example /var/www/livechat/.env`),
    sudoCmd(`cd /var/www/livechat && apt-get update && apt-get install -y dos2unix`),
    sudoCmd(`cd /var/www/livechat && dos2unix install.sh mail-setup.sh || true`),
    sudoCmd(`cd /var/www/livechat && chmod +x install.sh mail-setup.sh update.sh backup.sh`),
    sudoCmd(`cd /var/www/livechat && ./install.sh`),
    sudoCmd(`cd /var/www/livechat && ./mail-setup.sh`),
    sudoCmd(`cd /var/www/livechat && npm run seed`)
  ];

  function executeNext(index) {
    if (index >= commands.length) {
      console.log('Installation fully complete!');
      conn.end();
      return;
    }

    console.log(`\nExecuting: ${commands[index]}`);
    conn.exec(commands[index], { pty: true }, (err, stream) => {
      if (err) throw err;
      stream.on('close', (code, signal) => {
        console.log(`Command finished with code ${code}`);
        executeNext(index + 1);
      }).on('data', (data) => {
        process.stdout.write(data.toString('utf-8'));
      }).stderr.on('data', (data) => {
        process.stderr.write(data.toString('utf-8'));
      });
    });
  }

  executeNext(0);
}
