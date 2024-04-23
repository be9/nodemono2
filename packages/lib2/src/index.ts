import { info as nodeSassInfo } from 'node-sass';
import getCpuInfo from 'cpu-features';
import { VERSION as sqlite3Version } from 'sqlite3';
import { utils } from 'ssh2';

export interface SomeInfo {
  'node-sass': string;
  'cpu-features': getCpuInfo.CpuFeatures;
  sqlite3: string;
  ssh2: utils.sftp.STATUS_CODE;
}

/**
 * Return a ton of useless information but exercise all the packages imported above.
 */
export function getSomeInfo(): SomeInfo {
  return {
    'node-sass': nodeSassInfo,
    'cpu-features': getCpuInfo(),
    'sqlite3': sqlite3Version,
    'ssh2': utils.sftp.STATUS_CODE.OK,
  };
}
