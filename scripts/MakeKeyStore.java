import java.io.*;
import java.security.*;
import java.security.cert.*;
import java.security.spec.*;

public class MakeKeyStore {
    public static void main(String[] args) throws Exception {
        byte[] keyBytes = java.nio.file.Files.readAllBytes(new File("platform.pk8").toPath());
        PKCS8EncodedKeySpec spec = new PKCS8EncodedKeySpec(keyBytes);
        KeyFactory kf = KeyFactory.getInstance("RSA");
        PrivateKey privKey = kf.generatePrivate(spec);

        CertificateFactory cf = CertificateFactory.getInstance("X.509");
        X509Certificate cert = (X509Certificate) cf.generateCertificate(new FileInputStream("platform.x509.pem"));

        KeyStore ks = KeyStore.getInstance("PKCS12");
        ks.load(null, null);
        ks.setKeyEntry("platform", privKey, "password".toCharArray(), new java.security.cert.Certificate[]{cert});

        FileOutputStream fos = new FileOutputStream("platform.p12");
        ks.store(fos, "password".toCharArray());
        fos.close();
        System.out.println("Saved platform.p12 successfully!");
    }
}
