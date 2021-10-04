using System;
using System.Text;
using System.Windows.Forms;
using System.Runtime.InteropServices;

public static class VKeyUtil
{
    [DllImport("user32.dll", CharSet = CharSet.Unicode)]
    private static extern short VkKeyScanW(char ch);

    [DllImport("user32.dll")]
    private static extern int ToUnicode(uint wVirtKey, uint wScanCode, byte[] lpKeyState, [Out, MarshalAs(UnmanagedType.LPWStr)] StringBuilder pwszBuff, int cchBuff, uint wFlags);

    public static short GetKeyCodeFromChar(char ch)
    {
        return VkKeyScanW(ch);
    }

    public static string GetCharsFromKeys(Keys keys)
    {
        StringBuilder buf = new StringBuilder(10);
        byte[] keyboardState = new byte[256];

        ToUnicode((uint)keys, 0, keyboardState, buf, buf.Capacity, 0);
        return buf.ToString();
    }
}
