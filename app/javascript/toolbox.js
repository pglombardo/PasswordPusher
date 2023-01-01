
export default function toBoolean(candidate) {
    if (candidate) {
        if (typeof candidate === 'string') {
            return candidate == 'true';
        } else if (typeof candidate === 'boolean') {
            return candidate;
        }
    }
    return null;
}
