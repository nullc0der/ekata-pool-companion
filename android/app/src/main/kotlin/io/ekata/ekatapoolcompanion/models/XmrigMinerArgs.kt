package io.ekata.ekatapoolcompanion.models

import android.os.Parcel
import android.os.Parcelable


class XmrigMinerArgs(val minerConfigPath: String?, val threadCount: Int) : Parcelable {
    private constructor(parcel: Parcel) : this(
        parcel.readString(),
        parcel.readInt()
    )

    override fun writeToParcel(parcel: Parcel, flags: Int) {
        parcel.writeString(minerConfigPath)
        parcel.writeInt(threadCount)
    }

    override fun describeContents(): Int {
        return 0
    }

    companion object CREATOR : Parcelable.Creator<XmrigMinerArgs> {
        override fun createFromParcel(parcel: Parcel): XmrigMinerArgs {
            return XmrigMinerArgs(parcel)
        }

        override fun newArray(size: Int): Array<XmrigMinerArgs?> {
            return arrayOfNulls(size)
        }
    }
}
