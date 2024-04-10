import styles from "./page.module.css";
import { Code } from '@nodemono2/proto/build/google/rpc/code';
import { listEnumValues } from '@protobuf-ts/runtime';

// Unfortunately, this doesn't work yet:
// (cannot load Node packages like cpu-features referenced from @nodemono2/lib2).
// import { getSomeInfo } from '@nodemono2/lib2';

// Using the Node package directly.
import getCpuInfo from 'cpu-features';

export default async function Home() {
  const info = getCpuInfo();

  return (
    <main className={styles.main}>
      <div className={styles.description}>
        <p>
          This is a Next.js app
        </p>
      </div>
      <div>
        <h3>Listing a proto enum (google.rpc.Code):</h3>

        <ul>
          {listEnumValues(Code).map(({name, number}) => {
            return <li key={name}>
              {name} = {number}
            </li>;
          })}
        </ul>
      </div>
      <div>
        {JSON.stringify(info, null, 2)}
      </div>
    </main>
  );
}
