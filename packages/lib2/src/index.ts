import { info as nodeSassInfo } from 'node-sass';
import getCpuInfo from 'cpu-features';
import { VERSION as sqlite3Version } from 'sqlite3';
import { utils } from 'ssh2';

/**
 * Return a ton of useless information but exercise all the packages imported above.
 */
export function getSomeInfo(): any {
  return {
    'node-sass': nodeSassInfo,
    'cpu-features': getCpuInfo(),
    'sqlite3': sqlite3Version,
    'ssh2': utils.sftp.STATUS_CODE,
  };
}
