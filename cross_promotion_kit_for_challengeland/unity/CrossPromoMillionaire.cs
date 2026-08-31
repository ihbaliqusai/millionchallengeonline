using UnityEngine;

public class CrossPromoMillionaire : MonoBehaviour
{
    private const string PackageName = "net.androidgaming.millionaire2024";
    private const string PlayStoreUrl = "https://play.google.com/store/apps/details?id=net.androidgaming.millionaire2024";

    public void OpenMillionaireGame()
    {
#if UNITY_ANDROID && !UNITY_EDITOR
        try
        {
            using (AndroidJavaClass unityPlayer = new AndroidJavaClass("com.unity3d.player.UnityPlayer"))
            using (AndroidJavaObject currentActivity = unityPlayer.GetStatic<AndroidJavaObject>("currentActivity"))
            using (AndroidJavaObject packageManager = currentActivity.Call<AndroidJavaObject>("getPackageManager"))
            {
                AndroidJavaObject launchIntent = null;
                try
                {
                    launchIntent = packageManager.Call<AndroidJavaObject>("getLaunchIntentForPackage", PackageName);
                }
                catch {}

                if (launchIntent != null)
                {
                    currentActivity.Call("startActivity", launchIntent);
                    return;
                }
            }
        }
        catch (System.Exception e)
        {
            Debug.LogWarning("Error checking installed app: " + e.Message);
        }

        // Fallback to Google Play Store / Browser
        try
        {
            Application.OpenURL("market://details?id=" + PackageName);
        }
        catch
        {
            Application.OpenURL(PlayStoreUrl);
        }
#else
        Application.OpenURL(PlayStoreUrl);
#endif
    }
}
