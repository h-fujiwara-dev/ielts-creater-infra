import { KmsKeyringNode, buildClient, CommitmentPolicy } from "@aws-crypto/client-node";
import {
  SecretsManagerClient,
  GetSecretValueCommand,
} from "@aws-sdk/client-secrets-manager";
import { Resend } from "resend";

const secretsManager = new SecretsManagerClient({});

// Cognitoはエンベロープ暗号化（AWS Encryption SDKのメッセージフォーマット）でコードを渡すため、
// 生のkms:Decryptではなく AWS Encryption SDK で復号する必要がある（AWS公式ドキュメント準拠）。
const { decrypt } = buildClient(CommitmentPolicy.REQUIRE_ENCRYPT_ALLOW_DECRYPT);
const kmsKeyArn = process.env.KMS_KEY_ARN;
if (!kmsKeyArn) throw new Error("KMS_KEY_ARN is not set");
const keyring = new KmsKeyringNode({ generatorKeyId: kmsKeyArn, keyIds: [kmsKeyArn] });

// コールドスタート後のウォーム呼び出しで使い回すキャッシュ
let cachedApiKey: string | undefined;

interface CustomEmailSenderEvent {
  triggerSource: string;
  userName: string;
  request: {
    code?: string;
    userAttributes: Record<string, string>;
  };
}

const SUBJECT_BY_TRIGGER: Record<string, string> = {
  CustomEmailSender_SignUp: "【IELTS Creator】確認コードのお知らせ",
  CustomEmailSender_ResendCode: "【IELTS Creator】確認コードの再送",
  CustomEmailSender_ForgotPassword: "【IELTS Creator】パスワード再設定コード",
  CustomEmailSender_UpdateUserAttribute: "【IELTS Creator】メールアドレス変更の確認コード",
  CustomEmailSender_AdminCreateUser: "【IELTS Creator】仮パスワードのお知らせ",
};

async function resolveApiKey(): Promise<string> {
  if (cachedApiKey) return cachedApiKey;

  const secretArn = process.env.RESEND_API_KEY_SECRET_ARN;
  if (!secretArn) throw new Error("RESEND_API_KEY_SECRET_ARN is not set");

  const result = await secretsManager.send(
    new GetSecretValueCommand({ SecretId: secretArn })
  );
  if (!result.SecretString) throw new Error("Resend API key secret has no string value");

  cachedApiKey = result.SecretString;
  return cachedApiKey;
}

// CognitoのCustom Email Senderトリガー契約（AWSドキュメント準拠）:
// event.request.code はAWS Encryption SDKでエンベロープ暗号化された確認コード（base64）。
export const handler = async (event: CustomEmailSenderEvent): Promise<void> => {
  const { request, userName, triggerSource } = event;

  if (!request.code) {
    // AccountTakeOverNotification等コードを伴わないトリガーは本チケットのスコープ外
    console.log(`skip: no code for triggerSource=${triggerSource}`);
    return;
  }

  const email = request.userAttributes.email;
  if (!email) {
    throw new Error(`email attribute not found for userName=${userName}`);
  }

  const { plaintext } = await decrypt(keyring, Buffer.from(request.code, "base64"));
  const code = Buffer.from(plaintext).toString("utf-8");

  const apiKey = await resolveApiKey();
  const resend = new Resend(apiKey);
  const fromEmail = process.env.RESEND_FROM_EMAIL;
  if (!fromEmail) throw new Error("RESEND_FROM_EMAIL is not set");

  const subject = SUBJECT_BY_TRIGGER[triggerSource] ?? SUBJECT_BY_TRIGGER.CustomEmailSender_SignUp;

  const { error } = await resend.emails.send({
    from: fromEmail,
    to: email,
    subject,
    html: `<p>確認コード: <strong>${code}</strong></p><p>このコードに心当たりがない場合は、本メールを破棄してください。</p>`,
  });

  if (error) {
    throw new Error(`Resend send failed: ${JSON.stringify(error)}`);
  }
};
