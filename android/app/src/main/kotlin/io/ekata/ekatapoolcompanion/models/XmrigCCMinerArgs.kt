package io.ekata.ekatapoolcompanion.models

import android.os.Parcel
import android.os.Parcelable

class XmrigCCMinerArgs(
    val minerConfigPath: String?,
    val threadCount: Int,
    val xmrigCCSeverUrl: String?,
    val xmrigCCServerToken: String?,
    val xmrigCCWorkerId: String?
) : Parcelable {
    private constructor(parcel: Parcel) : this(
        parcel.readString(),
        parcel.readInt(),
        parcel.readString(),
        parcel.readString(),
        parcel.readString()
    )

    override fun writeToParcel(parcel: Parcel, flags: Int) {
        parcel.writeString(minerConfigPath)
        parcel.writeInt(threadCount)
        parcel.writeString(xmrigCCSeverUrl)
        parcel.writeString(xmrigCCServerToken)
        parcel.writeString(xmrigCCWorkerId)
    }

    override fun describeContents(): Int {
        return 0
    }

    companion object CREATOR : Parcelable.Creator<XmrigCCMinerArgs> {
        override fun createFromParcel(parcel: Parcel): XmrigCCMinerArgs {
            return XmrigCCMinerArgs(parcel)
        }

        override fun newArray(size: Int): Array<XmrigCCMinerArgs?> {
            return arrayOfNulls(size)
        }
    }
}